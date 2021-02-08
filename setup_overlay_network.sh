#!/usr/bin/env bash
set -x

# shellcheck disable=SC1091
source lib/common.sh
# shellcheck disable=SC1091
source lib/network.sh

# Overlay network related variables
VXLAN_NAME_BAREMETAL=${VXLAN_NAME_BAREMETAL:-"vxlan10"}
VXLAN_NAME_PROVISIONING=${VXLAN_NAME_PROVISIONING:-"vxlan20"}
VXLAN_ID_BAREMETAL=${VXLAN_ID_BAREMETAL:-"10"}
VXLAN_ID_PROVISIONING=${VXLAN_ID_PROVISIONING:-"20"}
WORKER_HOST_IP=${WORKER_HOST_IP:-"10.201.10.38"}
MASTER_HOST_IP=${MASTER_HOST_IP:-"10.201.10.34"}
#MULTICAST_IP_BAREMETAL=${MULTICAST_IP_BAREMETAL:-"239.1.1.1"}
#MULTICAST_IP_PROVISIONING=${MULTICAST_IP_PROVISIONING:-"239.1.1.2"}
NETWORK_INTERFACE=${NETWORK_INTERFACE:-"ens3"}
BRIDGE_NAME_BAREMETAL=${BRIDGE_NAME_BAREMETAL:-"baremetal"}
BRIDGE_NAME_PROVISIONING=${BRIDGE_NAME_PROVISIONING:-"provisioning"}
MTU_SIZE=${MTU_SIZE:-"8900"}
#IRONICENDPOINT_MTU_SIZE=${IRONICENDPOINT_MTU_SIZE:-"8900"}
PORT_ID=${PORT_ID:-"0"}

#Delete old vxlan configurations
sudo ip link delete "$VXLAN_NAME_BAREMETAL"
sudo ip link delete "$VXLAN_NAME_PROVISIONING"

# (Note) Below line outputs IP address of ens3 interface without CIDR notation(i.e 10.201.10.50).
# in case we will need it.

# ip a | grep ens3 | cut -d " " -f6 | awk 'NR==2{print $1}' | cut -d "/" -f 1

# Description:
# Setup overlay networks (baremetal or provisioning)
#
# Usage:
#   setup_overlay_network <VXLAN_NAME> <VXLAN_ID> <REMOTE_IP> <PORT_ID> \
#   <NETWORK_INTERFACE> <BRIDGE_NAME> <PROVISIONING_INTERFACE> <MTU_SIZE>
#

if [ "${VM_ID}" == 1 ]; then
    IP=${IP:-"$WORKER_HOST_IP"}
else
    IP=${IP:-"$MASTER_HOST_IP"}
fi

function setup_overlay_network() {
    local VXLAN_NAME="$1"
    local VXLAN_ID="$2"
    local IP="$3"
    #local MASTER_IP="$4"
    #local DESTINATION_PORT="$5"
    local INTERFACE="$4"
    local BRIDGE_NAME="$5"
    local PROVISIONING_INTERFACE="$6"
    local MTU="$7"
    #local IEMTU="$8"
    #local VM_ID="$8"

    sudo ip link add "${VXLAN_NAME}" type vxlan id "${VXLAN_ID}" remote "${IP}" dstport 0 dev "${INTERFACE}"
    sudo ip link set "${VXLAN_NAME}" master "${BRIDGE_NAME}"
    sudo ip link set "${VXLAN_NAME}" up
    sudo ip link set dev "${PROVISIONING_INTERFACE}" mtu "${MTU}"
    sudo ip link set dev "${BRIDGE_NAME_BAREMETAL}" mtu "${MTU}"
    sudo ip link set dev "${BRIDGE_NAME_PROVISIONING}" mtu "${MTU}"
    sudo ip link set dev ironic-peer mtu "${MTU}"
    sudo ip link set dev baremetal-nic mtu "${MTU}"
}

# Setup baremetal overlay network
setup_overlay_network "$VXLAN_NAME_BAREMETAL" "$VXLAN_ID_BAREMETAL"  "$IP" \
"$NETWORK_INTERFACE" "$BRIDGE_NAME_BAREMETAL" "$CLUSTER_PROVISIONING_INTERFACE" "$MTU_SIZE"

# Setup provisioning overlay network
setup_overlay_network "$VXLAN_NAME_PROVISIONING" "$VXLAN_ID_PROVISIONING"  "$IP" \
"$NETWORK_INTERFACE" "$BRIDGE_NAME_PROVISIONING" "$CLUSTER_PROVISIONING_INTERFACE" "$MTU_SIZE"

# Delete kind cluster for worker VMs'
if [ "${VM_ID}" != 1 ]; then
    sudo kind delete cluster
fi