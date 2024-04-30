talosctl gen config talos-proxmox-cluster https://192.168.178.80:6443 \
    --force \
    --output-dir talos/config \
    --config-patch @talos/patch/all.yaml \
    --config-patch-control-plane @talos/patch/controlplane.yaml