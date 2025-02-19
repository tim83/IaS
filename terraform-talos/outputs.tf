output "talosconfig" {
  value     = data.talos_client_configuration.talos.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = resource.talos_cluster_kubeconfig.talos.kubeconfig_raw
  sensitive = true
}

output "controllers" {
  value = join(",", [for node in merge(local.controller_nodes, local.hybrid_nodes) : node.address])
}

output "workers" {
  value = join(",", [for node in local.worker_nodes : node.address])
}
