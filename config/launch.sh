#!/bin/bash

function gen_config() {
    echo "Enter Firecracker IP Address (default: 169.254.0.21)"
    read input
    firecracker_ip=${input:="169.254.0.21"}

    echo "Enter TAP IP Address (default: 169.254.0.22)"
    read input
    tap_ip=${input:="169.254.0.22"}

    echo "Enter guest MAC address (default: 02:FC:00:00:00:05)"
    read input
    guest_mac=${input:="02:FC:00:00:00:05"}

    echo "Enter VM memory usage (default: 128 mib)"
    read input
    mem=${input:="128"}

    echo "Enter TAP name (default: tap-fc-dev)"
    read input
    tap_name=${input:="tap-fc-dev"}

    MASK_LONG="255.255.255.252"
    MASK_SHORT="/30"
    KERNEL_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on"
    KERNEL_BOOT_ARGS="${KERNEL_BOOT_ARGS} ip=${firecracker_ip}::${tap_ip}:${MASK_LONG}::eth0:off"

    echo "Configuration settings:"
    echo " IP: ${firecracker_ip}"
    echo " MAC: ${guest_mac}"
    echo " TAP Name: ${tap_name}"
    echo " Memory: ${mem} mib"
    echo " Mask: ${MASK_LONG}/${MASK_SHORT}"
    echo " Kernel Boot Args: ${KERNEL_BOOT_ARGS}"
    echo ""

    echo "To keep things simple, we're creating the TAP device now..."

    sudo ip link del "$tap_name" 2> /dev/null || true
    sudo ip tuntap add dev "$tap_name" mode tap
    sudo sysctl -w net.ipv4.conf.${tap_name}.proxy_arp=1 > /dev/null
    sudo sysctl -w net.ipv6.conf.${tap_name}.disable_ipv6=1 > /dev/null
    sudo ip addr add "${tap_ip}${MASK_SHORT}" dev "$tap_name"
    sudo ip link set dev "$tap_name" up

    echo "✅ TAP network created"

    cat <<EOF > /firecracker/configs/alpine-config.json
    {
        "boot-source": {
            "kernel_image_path": "/firecracker/kernel/kernel.bin",
            "boot_args": "${KERNEL_BOOT_ARGS}"
        },
        "drives": [
            {
                "drive_id": "rootfs",
                "path_on_host": "/firecracker/fs/alpine-base-root.ext4",
                "is_root_device": true,
                "is_read_only": false
            }
        ],
        "network-interfaces": [
            {
                "iface_id": "eth0",
                "guest_mac": "${guest_mac}",
                "host_dev_name": "${tap_name}"
            }
        ],
        "machine-config": {
            "vcpu_count": 1,
            "mem_size_mib": ${mem}
        }
    }
EOF
}