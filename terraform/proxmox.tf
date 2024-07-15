# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_download_file" "talos" {
  datastore_id = "local"
  node_name    = "pve"
  content_type = "iso"

  url       = "https://factory.talos.dev/image/${var.talos_factory_id}/v${var.talos_version}/nocloud-amd64.iso"
  file_name = "talos-v${var.talos_version}-nocloud-amd64-${var.talos_factory_id}.iso"
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "controller" {
  count           = var.controller_count
  name            = "${var.prefix}-${local.controller_nodes[count.index].name}"
  node_name       = "pve"
  tags            = sort(["talos", "controller", "terraform"])
  stop_on_destroy = true
  bios            = "ovmf"
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = 4
  }
  memory {
    dedicated = 2 * 1024
  }
  vga {
    type = "qxl"
  }
  network_device {
    bridge   = "vmbr0"
    firewall = true
  }
  tpm_state {
    version = "v2.0"
  }
  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.talos.id
  }
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 60
    file_format  = "raw"
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${local.controller_nodes[count.index].address}/16"
        gateway = var.cluster_node_network_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "worker" {
  count           = var.worker_count
  name            = "${var.prefix}-${local.worker_nodes[count.index].name}"
  node_name       = "pve"
  tags            = sort(["talos", "worker", "terraform"])
  stop_on_destroy = true
  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = 4
  }
  memory {
    dedicated = 4 * 1024
  }
  vga {
    type = "qxl"
  }
  network_device {
    bridge   = "vmbr0"
    firewall = true
  }
  tpm_state {
    version = "v2.0"
  }
  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.talos.id
  }
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 60
    file_format  = "raw"
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${local.worker_nodes[count.index].address}/16"
        gateway = var.cluster_node_network_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}
