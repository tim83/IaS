#! /bin/bash

# Install dependecies
terraform init -upgrade || exit 1

# Execute plan
terraform apply || exit 1

# Export outputs for use on this system
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config
