locals {
  pve_nodes = toset([for config in var.node_config : config.pve_node_name])
  all_nodes = merge(flatten([
    for config_idx, node_config in var.node_config : [
      for node_idx in range(node_config.count) : [
        {
          "${node_config.pve_node_name}-${node_config.node_type}-${config_idx * 10 + node_idx}" = merge(
            node_config,
            {
              address = cidrhost(var.cluster_node_network, config_idx * 10 + node_idx)
              name    = "${node_config.node_type}-${config_idx * 10 + node_idx}"
              idx     = config_idx * 10 + node_idx
            }
          )
        }
      ]
    ]
    ])...
  )
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_download_file" "talos" {
  for_each = local.pve_nodes

  node_name    = each.value
  datastore_id = "local"
  content_type = "iso"

  url       = "https://factory.talos.dev/image/${var.talos_factory_id}/v${var.talos_version}/nocloud-amd64.iso"
  file_name = "talos-v${var.talos_version}-nocloud-amd64-${var.talos_factory_id}.iso"

  overwrite_unmanaged = true
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "talos_node" {
  for_each = local.all_nodes

  name      = "${var.prefix}-${each.value.name}"
  node_name = each.value.pve_node_name
  vm_id     = 800 + each.value.idx

  tags            = sort(["talos", "terraform", each.value.node_type])
  stop_on_destroy = true
  bios            = "ovmf"
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = each.value.cpu_count
  }
  memory {
    dedicated = each.value.max_ram_gb * 1024
    floating  = each.value.max_ram_gb * 1024
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
    file_id = proxmox_virtual_environment_download_file.talos[each.value.pve_node_name].id
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
    size         = each.value.disk_size
    file_format  = "raw"
    ssd          = true
  }
  agent {
    enabled = true
    trim    = true
  }
  startup {
    order = each.value.node_type == "controller" ? "20" : "30"
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.address}/16"
        gateway = var.cluster_node_network_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

