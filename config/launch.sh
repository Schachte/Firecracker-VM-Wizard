#!/bin/bash

function gen_config() {
    echo "Enter TAP IP Address (default: 172.16.0.1/24)"
    read input
    tap_ip=${input:="172.16.0.1"}

    echo "Enter Firecracker IP Address (default: 172.16.0.2/24)"
    read input
    firecracker_ip=${input:="172.16.0.2"}

    echo "Enter guest MAC address (default: 02:FC:00:00:00:05)"
    read input
    guest_mac=${input:="02:FC:00:00:00:05"}

    echo "Enter VM memory usage (default: 128 mib)"
    read input
    mem=${input:="128"}

    echo "Enter TAP name (default: tap-fc-dev)"
    read input
    tap_name=${input:="tap-fc-dev"}

    MASK_LONG="255.255.255.0"
    MASK_SHORT="/24"
    KERNEL_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on"
    KERNEL_BOOT_ARGS="${KERNEL_BOOT_ARGS} ip=${firecracker_ip}::${tap_ip}:${MASK_LONG}::eth0:off"

    # just _in case_ it already exists, we will just wipe it
    sudo ip link del "$tap_name" 2> /dev/null || true

    # Add a tap device to act as a bridge between the microVM
    # and the host.
    sudo ip tuntap add dev $tap_name mode tap

    # The subnet is 172.16.0.0/24 and so the 
    # host will be 172.16.0.1 and the microVM is going to be set to 
    # 172.16.0.2
    sudo ip addr add $tap_ip$MASK_SHORT dev $tap_name
    sudo ip link set $tap_name up
    ip addr show dev $tap_name

    # Set up IP forwarding and masquerading

    # Change IFNAME to match your main ethernet adapter, the one that
    # accesses the Internet - check "ip addr" or "ifconfig" if you don't 
    # know which one to use.
    IFNAME=eth0

    # Enable IP forwarding
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

    # Enable masquerading / NAT - https://tldp.org/HOWTO/IP-Masquerade-HOWTO/ipmasq-background2.5.html
    sudo iptables -t nat -A POSTROUTING -o $IFNAME -j MASQUERADE
    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i $tap_name -o $IFNAME -j ACCEPT

    echo "✅ TAP network created"

    cat <<EOF > /firecracker/configs/alpine-config.json
    {
        "boot-source": {
            "kernel_image_path": "$2/kernel",
            "boot_args": "${KERNEL_BOOT_ARGS}"
        },
        "drives": [
            {
                "drive_id": "rootfs",
                "path_on_host": "$1/alpine-base-root.ext4",
                "is_root_device": true,
                "is_read_only": false
            }
        ],
        "network-interfaces": [
            {
                "iface_id": "eth0",
                "host_dev_name": "$tap_name",
                "guest_mac": "$guest_mac"
            }
        ],
        "machine-config": {
            "vcpu_count": 1,
            "mem_size_mib": 128
        }
    }
EOF
}