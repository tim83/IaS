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
  default = "1.10.6"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}

variable "talos_factory_id" {
  type    = string
  default = "88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b"
}

# see https://github.com/siderolabs/kubelet/pkgs/container/kubelet
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "kubernetes_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/kubelet
  default = "1.33.3"
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
  default     = "192.168.0.1"
}

variable "cluster_node_network" {
  description = "The IP network prefix of the cluster nodes"
  type        = string
  default     = "192.168.40.0/24"
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

variable "node_config" {
  type = list(object({
    pve_node_name = string
    node_type     = string
    start_idx     = number
    count         = number
    cpu_count     = number
    max_ram_gb    = number
    disk_size     = number
  }))
  default = [
    {
      pve_node_name = "thinkcentre"
      node_type     = "controller"
      start_idx     = 0
      count         = 1
      cpu_count     = 2
      max_ram_gb    = 16
      disk_size     = 60
    },
    {
      pve_node_name = "thinkcentre"
      node_type     = "worker"
      start_idx     = 0
      count         = 1
      cpu_count     = 12
      max_ram_gb    = 32
      disk_size     = 250
    },
    {
      pve_node_name = "coolermater"
      node_type     = "worker"
      start_idx     = 0
      count         = 1
      cpu_count     = 1
      max_ram_gb    = 4
      disk_size     = 450
    },
    {
      pve_node_name = "coolermater"
      node_type     = "hybrid"
      start_idx     = 0
      count         = 0
      cpu_count     = 3
      max_ram_gb    = 11
      disk_size     = 350
    },
    {
      pve_node_name = "coolermater"
      node_type     = "controller"
      start_idx     = 0
      count         = 0
      cpu_count     = 1
      max_ram_gb    = 2
      disk_size     = 60
    },
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