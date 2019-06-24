source config.sh

display_wait_for_lb=${display_wait_for_lb:-0}

wait_for_lb() {
    if [ $display_wait_for_lb -ne 0 ]; then
        comment "wait for ACTIVE state for $1 load balancer"
    fi
    while ! openstack loadbalancer show "$1" | grep 'provisioning_status' | grep -q ACTIVE; do
        sleep 2
    done
}

comment() {
    echo '#' $* >&2
}

cmd () {
    echo '$' $* >&2
    eval $*
}

silent () {
    $* > /dev/null
}
