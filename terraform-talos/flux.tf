resource "flux_bootstrap_git" "this" {
  embedded_manifests = true
  path               = "clusters/${var.cluster_name}"

  depends_on = [kubernetes_secret.sops-age]
}

resource "kubernetes_namespace" "flux-system" {
  metadata {
    name = "flux-system"
  }

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

  depends_on = [kubernetes_namespace.flux-system]
}