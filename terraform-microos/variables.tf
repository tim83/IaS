variable "proxmox_pve_node_name" {
  type    = string
  default = "pve"
}

variable "proxmox_pve_node_address" {
  type    = string
  default = "https://192.168.20.1:8006/api2/json"
}

variable "proxmox_pve_api_token" {
  type      = string
  sensitive = true
}

# see https://github.com/siderolabs/talos/releases
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "talos_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/talos
  default = "1.7.5"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}

variable "talos_factory_id" {
  type    = string
  default = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
}

# see https://github.com/siderolabs/kubelet/pkgs/container/kubelet
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "kubernetes_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/kubelet
  default = "1.30.2"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.kubernetes_version))
    error_message = "Must be a version number."
  }
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "home"
}

variable "cluster_node_network_gateway" {
  description = "The IP network gateway of the cluster nodes"
  type        = string
  default     = "192.168.0.1"
}

variable "cluster_node_network" {
  description = "The IP network prefix of the cluster nodes"
  type        = string
  default     = "192.168.40.0/24"
}

variable "cluster_node_network_first_controller_hostnum" {
  description = "The hostnum of the first controller host"
  type        = number
  default     = 80
}

variable "cluster_node_network_first_worker_hostnum" {
  description = "The hostnum of the first worker host"
  type        = number
  default     = 90
}

variable "cluster_node_network_load_balancer_first_hostnum" {
  description = "The hostnum of the first load balancer host"
  type        = number
  default     = 130
}

variable "cluster_node_network_load_balancer_last_hostnum" {
  description = "The hostnum of the last load balancer host"
  type        = number
  default     = 230
}

variable "controller_count" {
  type    = number
  default = 2
  validation {
    condition     = var.controller_count >= 1
    error_message = "Must be 1 or more."
  }
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "prefix" {
  type    = string
  default = "talos-home"
}

variable "github_token" {
  description = "GitHub token"
  sensitive   = true
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
  default     = "tim83"
}

variable "github_repository" {
  description = "GitHub repository"
  type        = string
  default     = "fluxcd"
}