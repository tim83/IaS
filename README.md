# How to configure my homelab?

## Prepare proxmox (for every node)

- Install proxmox
- Create user & API token

```bash
pveum role add Terraform -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt User.Modify"
pveum user add terraform@$HOSTNAME
pveum aclmod / -user terraform@$HOSTNAME -role Terraform
pveum user token add terraform@$HOSTNAME provider --privsep=0
```

## Run terraform

```bash
cd terraform-talos
bash apply.sh
```
