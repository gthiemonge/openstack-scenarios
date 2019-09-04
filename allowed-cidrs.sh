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
    openstack loadbalancer listener create --name listener1 --protocol HTTP --protocol-port 80 --allowed-cidr 10.5.0.0/16 --allowed-cidr 192.168.12.2/24 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener2 --protocol HTTP --protocol-port 82 --allowed-cidr 10.4.0.0/16 --allowed-cidr 192.168.12.2/24 lb1
wait_for_lb lb1

ds-sg-list
