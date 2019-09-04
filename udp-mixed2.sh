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
    openstack loadbalancer listener create --name listener1 --protocol UDP --protocol-port 80 lb1
wait_for_lb lb1

silent cmd \
    openstack loadbalancer pool create --name pool1 --lb-algorithm ROUND_ROBIN --listener listener1 --protocol UDP
wait_for_lb lb1

TOKEN=$(openstack token issue -f value -c id)
OCTAVIA_BASE_URL=$(openstack endpoint list --service octavia --interface public -c URL -f value)
pool_id=$(openstack loadbalancer pool show -f value -c id pool1)

cmd \
    'subnet4_id=$(openstack subnet show ipv4-members-subnet -c id -f value)'
cmd \
    'subnet6_id=$(openstack subnet show ipv6-members-subnet -c id -f value)'

curl -X PUT \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    -d '{"members":[{"name": "member1", "subnet_id": "'$subnet6_id'","address":"fe80::1","protocol_port":80},{"name": "member2", "subnet_id": "'$subnet4_id'","address":"192.0.1.2","protocol_port":80}]}' \
    ${OCTAVIA_BASE_URL}/v2.0/lbaas/pools/$pool_id/members

echo '# press enter to delete resources'
read a
