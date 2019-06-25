#!/bin/sh

export PATH=$PATH:${OS_SCENARIO_DIR:-./}

source common.sh

cmd \
    'subnet_id=$(openstack subnet show ipv4-vip-subnet -c id -f value)'
silent cmd \
    openstack loadbalancer create --name lb1 --vip-subnet-id \$subnet_id

trap "openstack loadbalancer delete lb1 --cascade; exit 0" EXIT INT
wait_for_lb lb1

silent cmd \
    openstack loadbalancer listener create --name listener1 --protocol UDP --protocol-port 80 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --name pool1 --lb-algorithm ROUND_ROBIN --listener listener1 --protocol UDP
wait_for_lb lb1

cmd \
    'server_name=$(openstack server list -c Name -f value | head -1)'
cmd \
    'server_address=$(openstack server show -c addresses -f value $server_name | grep -o "10\.0\.0\.[0-9]*")'
silent cmd \
    openstack loadbalancer member create --name member1 --subnet \$subnet_id --address \$server_address --protocol-port 80 pool1
#cmd \
#    'subnet_id=$(openstack subnet show ipv6-members-subnet -c id -f value)'
#silent cmd \
#    openstack loadbalancer member create --name member1 --subnet \$subnet_id --address fe80:789::4242 --protocol-port 8080 pool1
wait_for_lb lb1

echo '# press enter to delete resources'
read a
