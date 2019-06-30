#!/bin/bash

if [[ -f "/doNotBeHealthy.txt" ]]; then
    echo "This file exsit /doNotBeHealthy.txt, this mean a rebalance is running by me so mark as not ready..."
    exit 1;
fi

couchbase-cli server-list -u ${USER} -c localhost -p ${PASSWORD} > readiness.txt
amIHealthyAndActive=$(cat readiness.txt | grep $(hostname) | grep -v unhealthy | grep healthy | grep -v inactive | grep active | wc -l)
countOfHealthyAndActiveNodes=$(cat readiness.txt | grep -v unhealthy | grep healthy | grep -v inactive | grep active | wc -l)
if [[ $amIHealthyAndActive -eq 1 ]]; then
    echo "I'm ok";
    exit 0;
fi

if [[ $countOfHealthyAndActiveNodes -eq 0 ]]; then
    echo "no one healthy, let me try to start...";
    exit 0;
fi

# if I'm not healty, 
#check if the cluster busy with a rebalance
rebalanceNotRunning=$(couchbase-cli rebalance-status --cluster="${APP_NAME}-discovery:${PORT}" -u ${USER} -p ${PASSWORD} | grep notRunning | wc -l)
# the expected resutls from (couchbase-cli rebalance-status) is:
#(u'notRunning', u'Exception Msg')
#(u'Running', None)
#(u'notRunning', None)
if [[ $rebalanceNotRunning -eq 0 ]]; then
    echo "I'm not ok but a rebalance in progress, so I will mark myself not ready but will do no action to fix that...";
    exit 1;
else
    echo "I'm not ok"
    exit 1;
fi