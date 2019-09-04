#!/bin/sh

set -e

export PATH=$PATH:${OS_SCENARIO_DIR:-./}

source common.sh

cmd \
    'subnet_id=$(openstack subnet show ipv4-members-subnet -c id -f value)'
silent cmd \
    openstack loadbalancer create --name lb1 --vip-subnet-id \$subnet_id

register_lb lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener1 --protocol HTTP --protocol-port 80 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --name pool1 --lb-algorithm ROUND_ROBIN --listener listener1 --protocol HTTP
wait_for_lb lb1

silent cmd \
    openstack loadbalancer member create --name member1 --subnet \$subnet_id --address 10.0.0.105 --protocol-port 8080 pool1
wait_for_lb lb1

cmd \
    openstack loadbalancer listener show -c provisioning_status -f value listener1

echo '# Update certificates'
ds-octavia-certs-update > /dev/null 2>&1

sleep 10

silent cmd \
    openstack loadbalancer listener set --connection-limit 1000 listener1

silent cmd sleep 5

cmd \
    openstack loadbalancer listener show -c provisioning_status -f value listener1

silent cmd sleep 150

cmd \
    openstack loadbalancer listener show -c provisioning_status -f value listener1

silent cmd \
    openstack loadbalancer failover lb1
wait_for_lb lb1

cmd \
    openstack loadbalancer listener show -c provisioning_status -f value listener1

silent cmd \
    openstack loadbalancer listener set --connection-limit 1000 listener1

silent cmd sleep 5

cmd \
    openstack loadbalancer listener show -c provisioning_status -f value listener1

