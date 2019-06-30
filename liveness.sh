#!/bin/bash

amIinTheCluster=$(couchbase-cli server-list -u ${USER} -c ${APP_NAME}-discovery -p ${PASSWORD} | grep $(hostname) | wc -l)

if [[ $amIinTheCluster -ne 1 ]]; then
    echo "not ok";
    exit 1;
else 
    echo "ok";
fi