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
    openstack loadbalancer listener create --name listener1 --protocol HTTP --protocol-port 80 lb1
wait_for_lb lb1

sleep 5

silent cmd \
    openstack loadbalancer listener delete listener1
wait_for_lb lb1
