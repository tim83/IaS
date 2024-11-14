variable "kubernetes_host" {
  type      = string
  sensitive = true
}
variable "kubernetes_ca_b64" {
  type      = string
  sensitive = true
}
variable "kuberentes_cert_b64" {
  type      = string
  sensitive = true
}
variable "kuberentes_key_b64" {
  type      = string
  sensitive = true
}