# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.9.2"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    # see https://github.com/hashicorp/terraform-provider-cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.4"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.60.0"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
  }
}


provider "proxmox" {
  endpoint = var.proxmox_pve_node_address
  api_token = var.proxmox_pve_api_token
  insecure = true

  ssh {
    username = "root"
    agent = true
  }
}

provider "talos" {
}
