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
  default = "1.11.5"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}

variable "talos_factory_id" {
  type    = string
  default = "88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b"
}

variable "talos_rpi_factory_id" {
  type    = string
  default = "f8a903f101ce10f686476024898734bb6b36353cc4d41f348514db9004ec0a9d"
}

# see https://github.com/siderolabs/kubelet/pkgs/container/kubelet
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "kubernetes_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/kubelet
  default = "1.34.2"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.kubernetes_version))
    error_message = "Must be a version number."
  }
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "talos-home"
}

variable "cluster_vip" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "192.168.0.100"
}

variable "cluster_node_network_gateway" {
  description = "The IP network gateway of the cluster nodes"
  type        = string
  default     = "192.168.1.1"
}

variable "cluster_node_network" {
  description = "The IP network prefix of the cluster nodes"
  type        = string
  default     = "192.168.40.0/24"
}

variable "vm_node_config" {
  type = list(object({
    pve_node_name = string
    node_type     = string
    start_idx     = optional(number, 0)
    count         = number
    cpu_count     = number
    max_ram_gb    = number
    disk_size     = number
  }))
  default = [
    {
      pve_node_name = "thinkcentre"
      node_type     = "worker"
      count         = 2
      cpu_count     = 5
      max_ram_gb    = 20
      disk_size     = 250
    },
    {
      pve_node_name = "coolermater"
      node_type     = "worker"
      count         = 0
      cpu_count     = 1
      max_ram_gb    = 4
      disk_size     = 400
    },
  ]
}

variable "metal_node_config" {
  type = list(object({
    device_type  = string
    node_type    = string
    bootstrap_ip = optional(string)
  }))
  default = [
    { device_type = "rpi", node_type = "controller" },
    { device_type = "rpi", node_type = "controller" },
    { device_type = "rpi", node_type = "controller" },
    { device_type = "rpi", node_type = "worker" },
  ]
}

variable "prefix" {
  type    = string
  default = "talos-home"
}


variable "git_repository" {
  description = "Git Repostory for Flux"
  type        = string
  default     = "https://gitlab.com/tmee/fluxcd.git"
}
variable "gitlab_token" {
  description = "GitLab token"
  sensitive   = true
  type        = string
}
