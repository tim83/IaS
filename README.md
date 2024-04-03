# Prepare proxmox

- Install proxmox
- Change proxmox repositories to use non-subscription repos
- Create MicroOS template
  - Download MicroOS qcow image (not containerhost)
  - Change image to include the "qemu-guest-agent": 
        `virt-customize -a openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2 --install qemu-guest-agent`
    - Docs: https://medium.com/@aj.abdelwahed/proxmox-creating-a-cloud-init-template-in-proxmox-55d1d1570e12
  - Create proxmox template from MicroOS image
    - https://pve.proxmox.com/wiki/Cloud-Init_Support
    - https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image

# Install talos
- https://www.talos.dev/v1.6/talos-guides/install/virtualized-platforms/proxmox/
- https://www.talos.dev/v1.6/talos-guides/network/vip/