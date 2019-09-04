#!/bin/sh

export PATH=$PATH:${OS_SCENARIO_DIR:-./}

source common.sh

cmd \
    'subnet_id=$(openstack subnet show private-subnet -c id -f value)'
silent cmd \
    openstack loadbalancer create --name lb1 --vip-subnet-id \$subnet_id

register_lb lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener1 --protocol PROXY --protocol-port 443 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --name pool1 --lb-algorithm ROUND_ROBIN --listener listener1 --protocol TERMINATED_HTTPS
wait_for_lb lb1
