#!/usr/bin/env bash
set -xe

# shellcheck disable=SC1091
source lib/network.sh

# Overlay network related variables
VXLAN_NAME_BAREMETAL=${VXLAN_NAME_BAREMETAL:-"vxlan10"}
VXLAN_NAME_PROVISIONING=${VXLAN_NAME_PROVISIONING:-"vxlan20"}
VXLAN_ID_BAREMETAL=${VXLAN_ID_BAREMETAL:-"10"}
VXLAN_ID_PROVISIONING=${VXLAN_ID_PROVISIONING:-"20"}
MULTICAST_IP_BAREMETAL=${MULTICAST_IP_BAREMETAL:-"239.1.1.1"}
MULTICAST_IP_PROVISIONING=${MULTICAST_IP_PROVISIONING:-"239.1.1.2"}
NETWORK_INTERFACE=${NETWORK_INTERFACE:-"ens3"}
BRIDGE_NAME_BAREMETAL=${BRIDGE_NAME_BAREMETAL:-"baremetal"}
BRIDGE_NAME_PROVISIONING=${BRIDGE_NAME_PROVISIONING:-"provisioning"}
MTU_SIZE=${MTU_SIZE:-"1450"}
PORT_ID=${PORT_ID:-"4789"}

# (Note) Below line outputs IP address of ens3 interface without CIDR notation(i.e 10.201.10.50).
# in case we will need it.
ip a | grep ens3 | cut -d " " -f6 | awk 'NR==2{print $1}' | cut -d "/" -f 1

# Description:
# Setup overlay networks (baremetal or provisioning)
#
# Usage:
#   setup_overlay_network <VXLAN_NAME> <VXLAN_ID> <REMOTE_IP> <PORT_ID> \
#   <NETWORK_INTERFACE> <BRIDGE_NAME> <PROVISIONING_INTERFACE> <MTU_SIZE>
#

function setup_overlay_network() {
    local VXLAN_NAME="$1"
    local VXLAN_ID="$2"
    local MULTICAST_IP="$3"
    local DESTINATION_PORT="$4"
    local INTERFACE="$5"
    local BRIDGE_NAME="$6"
    local PROVISIONING_INTERFACE="$7"
    local MTU="$8"
    
    sudo ip link add "${VXLAN_NAME}" type vxlan id "${VXLAN_ID}" group "${MULTICAST_IP}" dstport "${DESTINATION_PORT}" dev "${INTERFACE}"
    sudo ip link set "${VXLAN_NAME}" master "${BRIDGE_NAME}"
    sudo ip link set "${VXLAN_NAME}" up
    sudo ip link set dev "${PROVISIONING_INTERFACE}" mtu "${MTU}"
}

# Delete kind cluster
kind delete cluster

# Setup baremetal overlay network
setup_overlay_network "$VXLAN_NAME_BAREMETAL" "$VXLAN_ID_BAREMETAL"  "$MULTICAST_IP_BAREMETAL" "$PORT_ID" \
"$NETWORK_INTERFACE" "$BRIDGE_NAME_BAREMETAL" "$CLUSTER_PROVISIONING_INTERFACE" "$MTU_SIZE" 

# Setup provisioning overlay network
setup_overlay_network "$VXLAN_NAME_PROVISIONING" "$VXLAN_ID_PROVISIONING"  "$MULTICAST_IP_PROVISIONING" "$PORT_ID" \
"$NETWORK_INTERFACE" "$BRIDGE_NAME_PROVISIONING" "$CLUSTER_PROVISIONING_INTERFACE" "$MTU_SIZE"