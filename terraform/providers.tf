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
      version = "0.61.1"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.3"
    }
    github = {
      source  = "integrations/github"
      version = "6.1"
    }
  }
}


provider "proxmox" {
  endpoint  = var.proxmox_pve_node_address
  api_token = var.proxmox_pve_api_token
  insecure  = true

  ssh {
    username = "root"
    agent    = true
  }
}

provider "talos" {
}

provider "flux" {
  kubernetes = {
    host                   = data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.host
    client_certificate     = data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate
    client_key             = data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key
    cluster_ca_certificate = data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate
  }
  git = {
    url = "https://github.com/${var.github_org}/${var.github_repository}.git"
    http = {
      username = "personal-access-token" # This can be any string when using a personal access token
      password = var.github_token
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}