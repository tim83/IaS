resource "kubernetes_namespace_v1" "flux-system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }

  depends_on = [time_sleep.wait_for_cluster_ip]
}
resource "kubernetes_secret_v1" "sops-age" {
  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }

  data = {
    "age.agekey" = "${file("${path.module}/../../fluxcd/age.agekey")}"
  }

  depends_on = [kubernetes_namespace_v1.flux-system]
}

resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace_v1.flux-system]

  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  wait       = true
}

data "http" "flux_instance_yaml" {
  url = "https://gitlab.com/tmee/fluxcd/-/raw/main/clusters/${var.cluster_name}/flux-instance.yaml"
}

resource "kubernetes_manifest" "flux_instance" {
  manifest = yamldecode(data.http.flux_instance_yaml.response_body)

  depends_on = [helm_release.flux_operator]
}
