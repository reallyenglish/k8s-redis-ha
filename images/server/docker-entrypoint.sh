#!/bin/bash
set -e

readonly conf=${REDIS_CONF_PATH:-/etc/redis/server.conf}
readonly template=${REDIS_CONF_TEMPLATE:-/etc/redis/server.conf.template}

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
    domain_to_ip "$(hostname)"
}

configure_redis () {
    local bind_address=${REDIS_BIND_ADDRESS:-$(default_bind_address)}
    local data_dir=${REDIS_DATA_DIR:-/data}

    sed -e "s|BIND|$bind_address|g" \
        -e "s|DIR|$data_dir|g" \
        $template > $conf

    local master_address=$(replication_master_address)
    if [ ! -z "$master_address" ]; then
        printf "\nslaveof %s 6379\n" "$master_address" >> $conf
    fi
}

configure_redis

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
