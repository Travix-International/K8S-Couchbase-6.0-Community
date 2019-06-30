#!/bin/bash
fqdn=$(hostname -f)
if [ -n "${USER}" ]; then
  export CB_REST_USERNAME=${USER}
fi
if [ -n "${PASSWORD}" ]; then
  export CB_REST_PASSWORD=${PASSWORD}
fi

couchbase-cli failover --cluster="${APP_NAME}-discovery:${PORT}" \
--server-failover="${fqdn}:${PORT}" \
--user="${CB_REST_USERNAME}" \
--password="${CB_REST_PASSWORD}"

sleep 15