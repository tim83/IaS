locals {
  all_nodes_complete = {
    for key, node_config in local.all_nodes :
          key => merge(
        node_config,
        {
          bootstrap_ip = can(node_config.bootstrap_ip) ? node_config.bootstrap_ip : node_config.address
        }
      )
    }
    controller_nodes = {
    for key, node_config in local.all_nodes_complete : key => node_config
    if node_config.node_type == "controller"
  }
  hybrid_nodes = {
    for key, node_config in local.all_nodes_complete : key => node_config
    if node_config.node_type == "hybrid"
  }
  worker_nodes = {
    for key, node_config in local.all_nodes_complete : key => node_config
    if node_config.node_type == "worker"
  }
  first_controller_node = length(local.controller_nodes) > 0 ? local.controller_nodes[keys(local.controller_nodes)[0]] : local.hybrid_nodes[keys(local.hybrid_nodes)[0]]
  first_controller_ip   = local.first_controller_node.address
}
locals {
  vm_config_patch = {
    machine = {
      install = {
        disk  = "/dev/sda"
        image = "factory.talos.dev/installer/${var.talos_factory_id}:v${var.talos_version}"
      }
    }
  }
  rpi_config_patch = {
    machine = {
      install = {
        disk  = "/dev/sda"
        image = "factory.talos.dev/installer/${var.talos_rpi_factory_id}:v${var.talos_version}"
      }
    }
  }
  controller_config_patch = {
    network = {
      interfaces = [
        # see https://www.talos.dev/v1.7/talos-guides/network/vip/
        {
          deviceSelector = {
            busPath = "0*"
          },
          vip = {
            ip = var.cluster_vip
          }
        }
      ]
    },
  }
  hybrid_config_patch = {
    cluster = {
      allowSchedulingOnControlPlanes = true,
    },
  }
  worker_config_patch = {
    kubelet = {
      extraMounts = [{
        destination = "/var/lib/longhorn",
        type        = "bind",
        source      = "/var/lib/longhorn"
        options = [
          "bind", "rshared", "rw",
        ]
        }
      ]
    }
  }
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_secrets
resource "talos_machine_secrets" "talos" {
  talos_version = "v${var.talos_version}"
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/machine_configuration
data "talos_machine_configuration" "controller" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_vip}:6443"
  machine_secrets    = talos_machine_secrets.talos.machine_secrets
  machine_type       = "controlplane"
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/machine_configuration
data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_vip}:6443"
  machine_secrets    = talos_machine_secrets.talos.machine_secrets
  machine_type       = "worker"
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version
  examples           = false
  docs               = false
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/client_configuration
data "talos_client_configuration" "talos" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoints            = [for node in local.controller_nodes : node.address]
}

resource "talos_cluster_kubeconfig" "talos" {
  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoint             = local.first_controller_ip
  node                 = local.first_controller_ip
  depends_on = [
    talos_machine_bootstrap.talos,
  ]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_configuration_apply
resource "talos_machine_configuration_apply" "controller" {
  for_each = local.controller_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration
  endpoint                    = each.value.bootstrap_ip
  node                        = each.value.address
  config_patches = [
    each.value.device_type == "vm" ? yamlencode(local.vm_config_patch) : "",
    each.value.device_type == "rpi" ? yamlencode(local.rpi_config_patch) : "",
    yamlencode(local.controller_config_patch)
  ]
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
}

resource "talos_machine_configuration_apply" "hybrid" {
  for_each = local.hybrid_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration
  endpoint                    = each.value.bootstrap_ip
  node                        = each.value.address
  config_patches = [
    each.value.device_type == "vm" ? yamlencode(local.vm_config_patch) : "",
    each.value.device_type == "rpi" ? yamlencode(local.rpi_config_patch) : "",
    yamlencode(local.controller_config_patch),
    yamlencode(local.hybrid_config_patch),
    yamlencode(local.worker_config_patch)
  ]
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.worker_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = each.value.bootstrap_ip
  node                        = each.value.address
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
  config_patches = [
    each.value.device_type == "vm" ? yamlencode(local.vm_config_patch) : "",
    each.value.device_type == "rpi" ? yamlencode(local.rpi_config_patch) : "",
    yamlencode(local.worker_config_patch)
  ]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_bootstrap
resource "talos_machine_bootstrap" "talos" {
  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoint             = local.first_controller_ip
  node                 = local.first_controller_ip
  depends_on = [
    talos_machine_configuration_apply.controller,
  ]
}

resource "time_sleep" "wait_for_cluster_ip" {
  create_duration = "90s"

  depends_on = [talos_machine_bootstrap.talos]
}