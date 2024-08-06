resource "flux_bootstrap_git" "this" {
  embedded_manifests = true
  path               = "clusters/${var.cluster_name}"
  components_extra = ["image-reflector-controller","image-automation-controller"]
}