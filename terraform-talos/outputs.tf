output "talosconfig" {
  value     = data.talos_client_configuration.talos.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.talos.kubeconfig_raw
  sensitive = true
}

output "controllers" {
  value = join(",", [for node in local.controller_nodes : node.address])
}

output "workers" {
  value = join(",", [for node in local.worker_nodes : node.address])
}

resource "local_file" "kubeconfig" {
  filename = pathexpand("~/.kube/config")
  content = data.talos_cluster_kubeconfig.talos.kubeconfig_raw
}

resource "local_file" "talosconfig" {
  filename = pathexpand("~/.talos/config")
  content = data.talos_client_configuration.talos.talos_config
}