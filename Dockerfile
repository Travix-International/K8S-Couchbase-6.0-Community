FROM couchbase/server:community-6.0.0

MAINTAINER Travix

RUN apt-get update && \
    apt-get install -yq curl iputils-ping && \
    apt-get autoremove && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# runtime environment variables
ENV AUTO_FAILOVER_TIMEOUT="30" \
    CB_REST_PASSWORD="" \
    CB_REST_USERNAME="Administrator" \
    CLUSTER_NAME="Couchbase Cluster (community-6.0.0)" \
    DISCOVERY_SERVICE="" \
    ENABLE_AUTO_FAILOVER="1" \
    FTS_RAM_SIZE_MB="1024" \
    INDEX_RAM_SIZE_MB="1024" \
    PORT="8091" \
    RAM_SIZE_MB="1024" \
    REBALANCE_ON_NODE_ADDITION="0" \
    SERVICES="data,index,query,fts" \
    STORAGE_SETTING="default"

COPY ./docker-entrypoint.sh /
COPY ./liveness.sh /
COPY ./readiness.sh /
COPY ./prestop.sh /

RUN chmod 500 /docker-entrypoint.sh
RUN chmod 500 /liveness.sh
RUN chmod 500 /readiness.sh
RUN chmod 500 /prestop.sh

# https://developer.couchbase.com/documentation/server/current/install/install-ports.html
EXPOSE 4369 8091-8094 9100-9105 9998-9999 11207 11209-11211 11214 11215 18091-18093 21100-21299

ENTRYPOINT ["/docker-entrypoint.sh"]
