# How to configure my homelab?

## Prepare proxmox (for every node)

- Install proxmox
- Change proxmox repositories to use non-subscription repos

```bash
sed -i "s/pve-enterprise/pve-no-subscription/" /etc/apt/sources.list.d/pve-enterprise.list
sed -i "s/enterprise.proxmox.com/download.proxmox.com/" /etc/apt/sources.list.d/pve-enterprise.list
sed -i "s/https/http/" /etc/apt/sources.list.d/pve-enterprise.list

sed -i "s/enterprise.proxmox.com/download.proxmox.com/" /etc/apt/sources.list.d/ceph.list
sed -i "s/enterprise/no-subscription/" /etc/apt/sources.list.d/ceph.list
sed -i "s/https/http/" /etc/apt/sources.list.d/ceph.list
```

- Create user & API token

```bash
pveum role add Terraform -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt User.Modify"
pveum user add terraform@$HOSTNAME
pveum aclmod / -user terraform@$HOSTNAME -role Terraform
pveum user token add terraform@$HOSTNAME provider --privsep=0
```

## Install TrueNAS

- Install TrueNAS as a normal VM
- Passtrough the HDDs
  - Get the /dev/disk/by-id paths of the disks with `lsblk |awk 'NR==1{print $0" DEVICE-ID(S)"}NR>1{dev=$1;printf $0" ";system("find /dev/disk/by-id -lname \"*"dev"\" -printf \" %p\"");print "";}'|grep -v -E 'part|lvm'`

```bash
qm set 100 -scsi1 /dev/disk/by-id/ata-ST8000DM004-2U9188_ZR15MFTV
qm set 100 -scsi2 /dev/disk/by-id/ata-ST8000DM004-2U9188_ZR15NM8T
qm set 100 -scsi3 /dev/disk/by-id/ata-ST8000DM004-2U9188_ZR15LR09
```

## Run terraform

```bash
cd terraform-talos
bash apply.sh
```
