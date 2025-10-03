#! /bin/bash

# Install dependecies
tofu init -upgrade || exit 1

# Execute plan
tofu apply || exit 1

# Export outputs for use on this system
tofu output -raw kubeconfig > ~/.kube/config
tofu output -raw talosconfig > ~/.talos/config
