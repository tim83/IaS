#! /bin/bash

# Install dependecies
terraform init -upgrade || exit 1

# Create plan
terraform plan -out plan -var-file=secrets.tfvars || exit 1

# Execute plan
terraform apply plan || exit 1

# Export outputs for use on this system
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config