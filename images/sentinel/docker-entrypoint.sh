#!/bin/bash
set -e

readonly conf=${SENTINEL_CONF_PATH:-/etc/redis/sentinel.conf}
readonly template=${SENTINEL_CONF_TEMPLATE:-/etc/redis/sentinel.conf.template}

domain_to_ip () {
    getent hosts "$1" | cut -d' ' -f1
}

replication_role () {
    set +e
    local -r info=$(timeout 5 redis-cli -h "$1" info replication)
    set -e
    echo "$info" | grep -e '^role:' | cut -d':' -f2 | tr -d '[:space:]'
}

replication_master_address () {
    for peer in $(lookup-srv); do
        if [ "$(replication_role "$peer")" = 'master' ]; then
            domain_to_ip "$peer"
	          return
        fi
    done
    echo -n
}

default_bind_address () {
    # expect redis server is running on this host
    domain_to_ip "$(hostname)"
}

default_quorum_number () {
    local total=$(lookup-srv | wc -l)
    let number=$total/2+1
    echo $number
}

configure_sentinel () {
    local bind_address=${SENTINEL_BIND_ADDRESS:-$(default_bind_address)}
    local master_name=${REDIS_MASTER_NAME:-redis-ha}
    local quorum=${SENTINEL_QUORUM:-$(default_quorum_number)}
    local master_address=$(replication_master_address)

    while [ -z "$master_address" ]; do
        # retry until we get replication master's ip address
        sleep 1
        master_address=$(replication_master_address)
    done

    sed -e "s/BIND/$bind_address/g" \
        -e "s/QUORUM/$quorum/g" \
        -e "s/MASTER_NAME/$master_name/g" \
        -e "s/MASTER_ADDRESS/$master_address/g" \
        $template > $conf
}

configure_sentinel

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
	set -- redis-server "$@"
fi

# start container with `redis` user
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	  chown -R redis .
    chown redis $conf
	exec gosu redis "$0" "$@"
fi

exec "$@"
