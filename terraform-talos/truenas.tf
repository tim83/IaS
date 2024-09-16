# resource "proxmox_virtual_environment_download_file" "truenas" {
#   node_name    = "coolermaster"
#   datastore_id = "local"
#   content_type = "iso"

#   url       = "https://download.sys.truenas.net/TrueNAS-SCALE-Dragonfish/24.04.2.1/TrueNAS-SCALE-24.04.2.1.iso"
#   file_name = "TrueNAS-SCALE.iso"

#   overwrite_unmanaged = true
# }

# resource "proxmox_virtual_environment_vm" "truenas" {
#   vm_id = 100
#   name            = "truenas"
#   node_name       = "coolermaster"
#   stop_on_destroy = true
#   cpu {
#     type  = "host"
#     cores = 2
#   }
#   memory {
#     dedicated = 8 * 1024
#     floating  = 1 * 1024
#   }
#   network_device {
#     bridge   = "vmbr0"
#     firewall = true
#   }
#   tpm_state {
#     version = "v2.0"
#   }
#   cdrom {
#     enabled = true
#     file_id = proxmox_virtual_environment_download_file.truenas.id
#   }
#   disk {
#     datastore_id = "local-lvm"
#     interface    = "scsi0"
#     iothread     = true
#     discard      = "on"
#     size         = 60
#     file_format  = "raw"
#     ssd          = true
#   }
#   agent {
#     enabled = false
#   }
#   startup {
#     order = 10
#   }
# }

