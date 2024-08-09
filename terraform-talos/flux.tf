resource "flux_bootstrap_git" "this" {
  embedded_manifests = true
  path               = "clusters/${var.cluster_name}"
  components_extra   = ["image-reflector-controller", "image-automation-controller"]

  depends_on = [time_sleep.wait_for_cluster_ip]
}

resource "kubernetes_secret" "sops-age" {
  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }

  data = {
    "age.agekey" = "${file("${path.module}/../../fluxcd/age.agekey")}"
  }

  depends_on = [flux_bootstrap_git.this]
}