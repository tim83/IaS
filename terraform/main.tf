terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.api_url
  pm_api_token_id = var.token_id
  pm_api_token_secret = var.token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "kube-masters" {
  name = "kube-${count.index + 1}"
  count = 1
  target_node = var.proxmox_host
  
  clone = var.template_name
  full_clone  = "true"

  agent = 1 # Enables qemu-guest-agent
  os_type = "cloud-init"
  cloudinit_cdrom_storage = "local-lvm"

  cores   = 3
  sockets = 1
  cpu = "host"
  memory  = 2560

  ipconfig0 = "ip=192.168.30.1${count.index+1}/16,gw=192.168.0.1"
  bootdisk = "virtio0"
  disks {
    virtio {
      virtio0 {
        disk {
          size = 24
          storage = "local-lvm"
          iothread = true
        }
      }
    }
  }

  network {
    model = "virtio"
    bridge = var.nic_name
    tag = var.vlan_num
  }

  provisioner "remote-exec" {
    inline = [
      "INSTALL_K3S_VERSION=${var.k3s_version} k3s-install server --cluster-init --write-kubeconfig-mode=644"
    ]
  }
}