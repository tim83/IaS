locals {
  pve_nodes = toset([for config in var.vm_node_config : config.pve_node_name])
  _vm_nodes = flatten([
    for config_idx, node_config in var.vm_node_config : [
      for node_idx in range(node_config.count) : [
        merge(
          node_config,
          {
            device_type = "vm"
            key         = "${node_config.pve_node_name}-${node_config.node_type}-${config_idx * 10 + node_idx + node_config.start_idx}"
            vm_id       = 800 + config_idx * 10 + node_idx + node_config.start_idx
          }
        )
      ]
    ]
  ])
  _metal_nodes = flatten([
    for node_type_idx, node_type in ["controller", "worker", "hybrid"] : [
      for node_idx, node_config in [for node_config in var.metal_node_config : node_config if node_config.node_type == node_type] : [
        merge(
          node_config,
          {
            key = "${node_config.device_type}-${node_config.node_type}-${100 + node_idx + 10 * node_type_idx}"
          }
        )
      ]
    ]
  ])
}
locals {
  all_nodes = [
    for idx, node_config in concat(local._metal_nodes, local._vm_nodes) : merge(
      node_config,
      {
        name    = "${var.cluster_name}-${node_config.node_type}-${idx}",
        address = cidrhost(var.cluster_node_network, idx),
        idx     = idx + (can(node_config.start_idx) ? node_config.start_idx : 0),
      }
    )
  ]
  vm_nodes = {
    for idx, node_config in local.all_nodes : node_config.key => node_config
    if node_config.device_type == "vm"
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_download_file" "talos" {
  for_each = local.pve_nodes

  node_name    = each.value
  datastore_id = "local"
  content_type = "iso"

  url       = "https://factory.talos.dev/image/${var.talos_factory_id}/v${var.talos_version}/nocloud-amd64-secureboot.iso"
  file_name = "talos-v${var.talos_version}-nocloud-amd64-secureboot-${var.talos_factory_id}.iso"

  overwrite_unmanaged = true
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.60.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "talos_node" {
  for_each = local.vm_nodes

  name      = each.value.name
  node_name = each.value.pve_node_name
  vm_id     = each.value.vm_id

  tags            = sort(["talos", "terraform", each.value.node_type])
  stop_on_destroy = true
  bios            = "ovmf"
  scsi_hardware   = "virtio-scsi-single"
  boot_order      = ["scsi0", "ide3", "net0"]
  operating_system {
    type = "l26"
  }
  cpu {
    type  = "host"
    cores = each.value.cpu_count
  }
  memory {
    dedicated = each.value.max_ram_gb * 1024
    floating  = 2 * 1024
  }
  network_device {
    bridge   = "vmbr0"
    firewall = true
  }
  tpm_state {
    version = "v2.0"
  }
  cdrom {
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
    size         = 35
    file_format  = "raw"
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi1"
    iothread     = true
    size         = each.value.disk_size
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.address}/17"
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

