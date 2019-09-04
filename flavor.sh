#!/bin/sh

set -e

export PATH=$PATH:${OS_SCENARIO_DIR:-./}

source common.sh

silent cmd \
    'openstack loadbalancer flavorprofile create --name active-standby --provider amphora --flavor-data "{\"loadbalancer_topology\": \"ACTIVE_STANDBY\"}"'

silent cmd \
    openstack loadbalancer flavor create --name active-standby --flavorprofile active-standby
