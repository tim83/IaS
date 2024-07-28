# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.9.3"
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
    flux = {
      source  = "fluxcd/flux"
      version = "1.3"
    }
    github = {
      source  = "integrations/github"
      version = "6.2"
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

provider "flux" {
  kubernetes = {
    host                   = "https://${var.cluster_vip}:6443"
    client_certificate     = base64decode(data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(data.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate)
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