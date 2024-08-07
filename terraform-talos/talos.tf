locals {
  controller_nodes = {
    for key, node_config in local.all_nodes: key => node_config
    if node_config.node_type == "controller"
  }
  worker_nodes = {
    for key, node_config in local.all_nodes: key => node_config
    if node_config.node_type == "worker"
  }
  first_controller_ip = local.controller_nodes[keys(local.controller_nodes)[0]].address
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

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/cluster_kubeconfig
data "talos_cluster_kubeconfig" "talos" {
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
  endpoint                    = each.value.address
  node                        = each.value.address
  config_patches = [
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true,
      },
      machine = {
        install = {
          disk  = "/dev/sda"
          image = "factory.talos.dev/installer/${var.talos_factory_id}:v${var.talos_version}"
        }
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
        }
      }
    }),
  ]
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_configuration_apply
resource "talos_machine_configuration_apply" "worker" {
  for_each = local.worker_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = each.value.address
  node                        = each.value.address
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = "/dev/sda"
          image = "factory.talos.dev/installer/${var.talos_factory_id}:v${var.talos_version}"
        }
      }
    })
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
  create_duration = "60s"

  depends_on = [talos_machine_bootstrap.talos]
}