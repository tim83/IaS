# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.10.5"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    # see https://github.com/hashicorp/terraform-provider-cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.5"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.72.0"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.4"
    }
    github = {
      source  = "integrations/github"
      version = "6.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
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

    node {
      name    = "thinkcentre"
      address = "192.168.20.1"
    }
    node {
      name    = "coolermater"
      address = "192.168.20.2"
    }
  }
}

provider "talos" {
}

provider "flux" {
  kubernetes = {
    host                   = var.kubernetes_host
    client_certificate     = base64decode(var.kuberentes_cert_b64)
    client_key             = base64decode(var.kuberentes_key_b64)
    cluster_ca_certificate = base64decode(var.kubernetes_ca_b64)
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

provider "kubernetes" {
  host                   = var.kubernetes_host                   # resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.host
  client_certificate     = base64decode(var.kuberentes_cert_b64) # resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate
  client_key             = base64decode(var.kuberentes_key_b64)  # resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key
  cluster_ca_certificate = base64decode(var.kubernetes_ca_b64)   # resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate
}