#!/bin/sh

set -e

export PATH=$PATH:${OS_SCENARIO_DIR:-./}

source common.sh

cmd \
    'subnet_id=$(openstack subnet show ipv4-vip-subnet -c id -f value)'
silent cmd \
    openstack loadbalancer create --name lb1 --vip-subnet-id \$subnet_id

trap "openstack loadbalancer delete lb1 --cascade; exit 0" EXIT INT
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener1 --protocol HTTP --protocol-port 80 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --lb-algorithm ROUND_ROBIN --loadbalancer lb1 --name pool_A --protocol HTTP
wait_for_lb lb1

cmd \
    'subnet_id=$(openstack subnet show ipv4-members-subnet -c id -f value)'
cmd \
    'server_name=$(openstack server list -c Name -f value | head -1)'
cmd \
    echo \$server_name
cmd \
    'server_address=$(openstack server show -c addresses -f value $server_name | grep -o "10\.0\.0\.[0-9]*")'
cmd \
    echo \$server_address

silent cmd \
    openstack loadbalancer member create --address \$server_address --protocol-port 8080 --subnet-id \$subnet_id pool_A
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --lb-algorithm ROUND_ROBIN --loadbalancer lb1 --name pool_B --protocol HTTP
wait_for_lb lb1

cmd \
    'server_name=$(openstack server list -c Name -f value | head -2 | tail -1)'
cmd \
    'server_address=$(openstack server show -c addresses -f value $server_name | grep -o "10\.0\.0\.[0-9]*")'

silent cmd \
    openstack loadbalancer member create --address \$server_address --protocol-port 8080 --subnet-id \$subnet_id pool_B
wait_for_lb lb1


silent cmd \
    openstack loadbalancer l7policy create --action REDIRECT_TO_POOL --redirect-pool pool_A --name policy1 --position 1 listener1
wait_for_lb lb1
silent cmd \
    openstack loadbalancer l7rule create --compare-type EQUAL_TO --key site_version --type COOKIE --value A policy1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer l7policy create --action REDIRECT_TO_POOL --redirect-pool pool_B --name policy2 --position 2 listener1
wait_for_lb lb1
silent cmd \
    openstack loadbalancer l7rule create --compare-type EQUAL_TO --key site_version --type COOKIE --value B policy2
wait_for_lb lb1

echo '# press enter to delete resources'
read a
