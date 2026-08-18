variable "proxmox_pve_node_address" {
  type    = string
  default = "https://10.30.2.12:8006/api2/json"
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
  default = "1.13.8"
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
  default = "1.36.3"
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
  default     = "10.30.2.200"
}

variable "cluster_node_network_gateway" {
  description = "The IP network gateway of the cluster nodes"
  type        = string
  default     = "10.30.2.1"
}

variable "cluster_node_network" {
  description = "The IP network prefix of the cluster nodes"
  type        = string
  default     = "10.30.2.32/28"
}

variable "vm_node_config" {
  type = list(object({
    pve_node_name  = string
    node_type      = string
    node_subtype   = optional(string)
    node_id        = optional(number)
    count          = number
    cpu_count      = number
    min_ram_gb     = optional(number, 2)
    max_ram_gb     = number
    disk_size      = number
    boot_disk_size = optional(number, 35)
  }))
  default = [
    {
      pve_node_name = "thinknugget"
      node_type     = "worker"
      node_id       = 3
      count         = 1
      cpu_count     = 6
      min_ram_gb    = 10
      max_ram_gb    = 10
      disk_size     = 150
    },
    {
      pve_node_name  = "thinkcentre"
      node_type      = "worker"
      node_id        = 4
      count          = 1
      cpu_count      = 10
      min_ram_gb     = 20
      max_ram_gb     = 20
      disk_size      = 250
      boot_disk_size = 50
    },
  ]
}

variable "metal_node_config" {
  type = list(object({
    device_type  = string
    node_type    = string
    node_subtype = optional(string)
    node_id      = optional(number)
    bootstrap_ip = optional(string)
  }))
  default = [
    { device_type = "rpi", node_type = "controller", node_id = 0 },
    { device_type = "rpi", node_type = "controller", node_id = 1 },
    { device_type = "rpi", node_type = "controller", node_id = 2 },
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
