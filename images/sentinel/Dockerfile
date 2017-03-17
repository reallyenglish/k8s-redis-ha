FROM redis:3.2.8

ADD ["https://github.com/ochko/lookup-srv/releases/download/v1.0.0/lookup-srv-linux-amd64", "/usr/local/bin/lookup-srv"]
RUN chmod +x /usr/local/bin/lookup-srv

ENV SENTINEL_CONF_PATH=${SENTINEL_CONF_PATH:-/etc/redis/sentinel.conf} \
    SENTINEL_CONF_TEMPLATE=${SENTINEL_CONF_TEMPLATE:-/etc/redis/sentinel.conf.template}

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 26379
CMD [ "redis-server", "/etc/redis/sentinel.conf", "--sentinel" ]