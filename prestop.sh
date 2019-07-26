#!/bin/bash
fqdn=$(hostname -f)

couchbase-cli failover --cluster="${APP_NAME}-discovery:${PORT}" \
--server-failover="${fqdn}:${PORT}" \
--user="${USER}" \
--password="${PASSWORD}" --force