#! /bin/bash

control_node=$(echo "var.cluster_vip" | tofu console | jq -r)
talos_version=$(echo "var.talos_version" | tofu console | jq -r)
talos_vm_factory_id=$(echo "var.talos_factory_id" | tofu console | jq -r)
talos_rpi_factory_id=$(echo "var.talos_rpi_factory_id" | tofu console | jq -r)
k8s_version=$(echo "var.kubernetes_version" | tofu console | jq -r)

talos_vm_image="factory.talos.dev/nocloud-installer/${talos_vm_factory_id}:v${talos_version}"
talos_rpi_image="factory.talos.dev/metal-installer/${talos_rpi_factory_id}:v${talos_version}"

nodes=$(talosctl get members -n $control_node -o json)
for node_ip in $(echo $nodes | jq -r ".spec|if .operatingSystem|contains(\"${talos_version}\")|not then . else null end|.addresses|arrays|map(select(. != \"${control_node}\"))|first") ; do
    hostname=$(talosctl get hostname -n $node_ip -o json | jq .spec.hostname)
    echo "$hostname ($node_ip)"
    if [[ $hostname =~ "rpi" ]]; then
        talos_image=$talos_rpi_image
    else
        talos_image=$talos_vm_image
    fi
    talosctl upgrade -n $node_ip --image $talos_image
done

if talosctl health -n $control_node --wait-timeout 15s > /dev/null 2>&1; then
    echo "Cluster successfully is healthy, continuing to k8s upgrade."
else
    echo "Cluster not healthy after upgrade, exiting."
    exit 1
fi

talosctl upgrade-k8s -n $control_node --to $k8s_version