#!/bin/sh

set -e

export PATH=$PATH:${OS_SCENARIO_DIR:-./}

source common.sh

on_exit () {
    echo '# press enter to delete resources'
    read a
    openstack loadbalancer delete lb1 --cascade
    exit 0
}

cmd \
    'subnet_id=$(openstack subnet show ipv4-members-subnet -c id -f value)'
silent cmd \
    openstack loadbalancer create --name lb1 --vip-subnet-id \$subnet_id

trap "on_exit" EXIT INT
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener1 --protocol HTTP --protocol-port 80 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --name pool1 --lb-algorithm ROUND_ROBIN --listener listener1 --protocol HTTP
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener2 --protocol HTTP --protocol-port 8000 --default-pool pool1 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer member create --name member1 --subnet \$subnet_id --address 10.0.0.105 --protocol-port 8080 pool1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer member create --name member2 --subnet \$subnet_id --address 192.168.0.12 --disable --protocol-port 8080 pool1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer member create --name member3 --subnet \$subnet_id --address 10.0.0.96 --protocol-port 8080 pool1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener3 --protocol UDP --protocol-port 81 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --name pool2 --lb-algorithm ROUND_ROBIN --listener listener3 --protocol UDP
wait_for_lb lb1

silent cmd \
    openstack loadbalancer member create --name member4 --subnet \$subnet_id --address 10.0.0.105 --protocol-port 8080 pool2
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener4 --protocol UDP --protocol-port 53 --default-pool pool2 lb1
wait_for_lb lb1
#
#    echo '# press enter'
#    read a
#
#silent cmd \
#    openstack loadbalancer listener delete listener1
