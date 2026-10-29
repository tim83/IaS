locals {
  // see https://www.talos.dev/v1.14/reference/configuration/document-map/ for the v1alpha1 -> config document migration
  vm_config_patch = [
    {
      apiVersion = "v1alpha1"
      kind       = "UnattendedInstallConfig"
      installer = {
        image = "factory.talos.dev/nocloud-installer-secureboot/${var.talos_factory_id}:v${var.talos_version}"
      }
      provisioning = {
        diskSelector = {
          match = "disk.dev_path == \"/dev/sda\""
        }
      }
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeNodeConfig"
      annotations = {
        "tuppr.home-operations.com/schematic" = var.talos_factory_id
      }
    },
  ]
  rpi_config_patch = [
    {
      apiVersion = "v1alpha1"
      kind       = "UnattendedInstallConfig"
      installer = {
        image = "factory.talos.dev/metal-installer/${var.talos_rpi_factory_id}:v${var.talos_version}"
      }
      provisioning = {
        diskSelector = {
          match = "disk.dev_path == \"/dev/mmcblk0\""
        }
      }
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeNodeConfig"
      annotations = {
        "tuppr.home-operations.com/schematic" = var.talos_rpi_factory_id
      }
    },
  ]
  hybrid_config_patch = { machine = { cluster = { allowSchedulingOnControlPlanes = true } } }

  device_type_config_patches = {
    rpi = local.rpi_config_patch
    vm  = local.vm_config_patch
  }
}
locals {
  all_nodes_complete = {
    for idx, node_config in local.all_nodes :
    node_config.key => merge(
      node_config,
      {
        bootstrap_ip = (can(node_config.bootstrap_ip) && node_config.bootstrap_ip != null) ? node_config.bootstrap_ip : node_config.address
        config_patches = compact(concat([
          // disable the default flannel CNI and kube-proxy in favor of Cilium (installed via Flux)
          yamlencode({
            apiVersion = "v1alpha1"
            kind       = "KubeFlannelCNIConfig"
            "$patch"   = "delete"
          }),
          // KubeProxyConfig is only allowed on control plane machines
          node_config.node_type != "worker" ? yamlencode({
            apiVersion = "v1alpha1"
            kind       = "KubeProxyConfig"
            enabled    = false
          }) : "",
          yamlencode({
            machine = {
              network = {
                interfaces = [
                  {
                    deviceSelector = { busPath = node_config.device_type == "rpi" ? "fd580000.ethernet" : "0*" },
                    addresses      = ["${node_config.address}/24"]
                    routes = [{
                      network = "0.0.0.0/0"
                      gateway = "10.30.2.1"
                    }]
                  }
                ]
              },
            }
          }),
          yamlencode({
            apiVersion = "v1alpha1"
            kind       = "ResolverConfig"
            nameservers = [
              for ns in ["10.30.2.1", "1.1.1.1", "8.8.8.8"] : { address = ns }
            ]
          }),
          yamlencode({
            machine = {
              sysctls = {
                "fs.inotify.max_user_watches"   = "1048576"
                "fs.inotify.max_user_instances" = "8192"
              }
            }
          }),
          node_config.node_type != "controller" ? yamlencode({
            machine = {
              sysctls = {
                "user.max_user_namespaces" = "65536"
              }
            }
          }) : "",
          node_config.node_type == "hybrid" ? yamlencode(local.hybrid_config_patch) : "",
          node_config.node_type != "worker" ? yamlencode({ machine = { network = { interfaces = [
            {
              deviceSelector = { busPath = node_config.device_type == "rpi" ? "fd580000.ethernet" : "0*" },
              vip            = { ip = var.cluster_vip }
            }
          ] } } }) : "",
          node_config.node_type != "worker" ? yamlencode({
            apiVersion = "v1alpha1"
            kind       = "KubeAuthenticationConfig"
            configuration = {
              apiVersion = "apiserver.config.k8s.io/v1"
              kind       = "AuthenticationConfiguration"
              jwt = [
                {
                  issuer = {
                    url                 = "https://pocketid.mees-olivier.com"
                    audiences           = ["16ec9bf8-64d6-4a84-bbc1-e842bb9c8523"]
                    audienceMatchPolicy = "MatchAny"
                  }
                  claimMappings = {
                    username = { claim = "email", prefix = "" }
                    groups   = { claim = "groups", prefix = "" }
                  }
                }
              ]
            }
          }) : "",
          yamlencode({ apiVersion = "v1alpha1", kind = "HostnameConfig", hostname = node_config.name, auto = "off" }),
          node_config.node_type != "worker" ? yamlencode({ # Needed for system-upgrade controller (tuppr)
            machine = {
              features = {
                kubernetesTalosAPIAccess = {
                  allowedKubernetesNamespaces = [
                    "system-upgrade"
                  ]
                  allowedRoles = [
                    "os:admin"
                  ]
                  enabled = true
                }
              }
            }
          }) : "",

          ], [
          for patch in try(local.device_type_config_patches[node_config.device_type], []) : yamlencode(patch)
        ]))
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
  node                        = each.value.bootstrap_ip

  config_patches = each.value.config_patches
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
}

resource "talos_machine_configuration_apply" "hybrid" {
  for_each = local.hybrid_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration
  endpoint                    = each.value.bootstrap_ip
  node                        = each.value.bootstrap_ip

  config_patches = each.value.config_patches
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.worker_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = each.value.bootstrap_ip
  node                        = each.value.bootstrap_ip
  depends_on = [
    proxmox_virtual_environment_vm.talos_node,
  ]
  config_patches = each.value.config_patches
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

resource "kubernetes_labels" "storage_nodes" {
  for_each = {
    for key, node in local.worker_nodes : key => node
    if try(node.node_subtype, "") == "storage"
  }

  api_version = "v1"
  kind        = "Node"
  metadata {
    name = each.value.name
  }
  labels = {
    "node-role.kubernetes.io/storage" = ""
  }

  depends_on = [
    talos_cluster_kubeconfig.talos,
    time_sleep.wait_for_cluster_ip
  ]
}

resource "kubernetes_node_taint" "storage_nodes" {
  for_each = {
    for key, node in local.worker_nodes : key => node
    if try(node.node_subtype, "") == "storage"
  }

  metadata {
    name = each.value.name
  }

  taint {
    key    = "node-role.kubernetes.io/storage"
    value  = "true"
    effect = "NoSchedule"
  }

  lifecycle {
    ignore_changes = [taint]
  }

  depends_on = [
    talos_cluster_kubeconfig.talos,
    time_sleep.wait_for_cluster_ip
  ]
}
