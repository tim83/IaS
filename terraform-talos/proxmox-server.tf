
resource "proxmox_virtual_environment_apt_standard_repository" "pve" {
  for_each = local.pve_nodes

  node    = each.value
  handle = "no-subscription"
}
resource "proxmox_virtual_environment_apt_repository" "pve" {
  for_each = local.pve_nodes

  node    = each.value

  enabled   = true
  file_path = proxmox_virtual_environment_apt_standard_repository.pve[each.value].file_path
  index     = proxmox_virtual_environment_apt_standard_repository.pve[each.value].index
}

resource "proxmox_virtual_environment_apt_standard_repository" "ceph" {
  for_each = local.pve_nodes

  node    = each.value
  handle = "ceph-quincy-no-subscription"
}
resource "proxmox_virtual_environment_apt_repository" "ceph" {
  for_each = local.pve_nodes

  node    = each.value

  enabled   = true
  file_path = proxmox_virtual_environment_apt_standard_repository.ceph[each.value].file_path
  index     = proxmox_virtual_environment_apt_standard_repository.ceph[each.value].index
}