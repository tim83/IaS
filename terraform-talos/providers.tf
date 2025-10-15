# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.10.6"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    # see https://github.com/hashicorp/terraform-provider-cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.7"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.85.1"
    }
    # see https://registry.terraform.io/providers/siderolabs/talos
    # see https://github.com/siderolabs/terraform-provider-talos
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
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
    host                   = resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.host
    client_certificate     = base64decode(resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate)
  }
  git = {
    url = var.git_repository
    http = {
      username = "fluxcd"
      password = var.gitlab_token
    }
  }
}

provider "kubernetes" {
  host                   = resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.host
  client_certificate     = base64decode(resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(resource.talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate)
}
