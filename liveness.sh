#!/bin/bash

amIinTheCluster=$(couchbase-cli server-list --cluster="${APP_NAME}-discovery:${PORT}" -u ${USER} -p ${PASSWORD} | grep $(hostname) | wc -l)

if [[ $amIinTheCluster -ne 1 ]]; then
    echo "not ok";
    exit 1;
else 
    echo "ok";
fi