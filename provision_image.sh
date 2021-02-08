#!/bin/bash
set -xe

# shellcheck disable=SC1091
source lib/common.sh

# shellcheck disable=SC1091
source lib/images.sh

VM_ID_COUNTER=1

# Calculate overall number of BMHs
let number_of_bmh=$NUM_NODES*$NUM_VMS

# Patch bmh crs yaml spec with corresponding IP to download image for node provisioning 
for ((bmh_id = 0 ; bmh_id < $number_of_bmh ; bmh_id++)); do

    if [ "$bmh_id" != "0" ] && [[ $bmh_id%6 -eq 0 ]]; then 
        if [ "$VM_ID_COUNTER" == "1" ]; then
            VM_ID_COUNTER=$((VM_ID_COUNTER + 2 ))
        else
            VM_ID_COUNTER=$((VM_ID_COUNTER + 1 ))
        fi
    fi
kubectl patch bmh node-$bmh_id -n metal3 --type merge -p '{"spec":{"image":{"checksum":"http://172.22.0.1/images/'${IMAGE_RAW_NAME}'.md5sum", "checksumType":"md5", "format":"raw", "url":"http://172.22.0.1/images/'${IMAGE_RAW_NAME}'"}}}'
done

