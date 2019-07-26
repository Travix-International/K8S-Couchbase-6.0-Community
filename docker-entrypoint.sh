#!/bin/bash

# Entrtpoint Logic:
# Call Discovery Service to check if there is a cluster already:
#   Case (No Cluster):
#     Init Cluster;
#   Case (Cluster Exists):
#     Is this node part of the cluster?:
#       Case (No):
#         Add node to the cluster
#       Case (Yes):
#         Re-Add node to the cluster

set -e

fqdn=$(hostname -f)
host=$(hostname)
HOSTNAME=${HOSTNAME:-"$host"}
HOSTNAME=${HOSTNAME%%.*}

# legacy
if [ -n "${USER}" ]; then
  export CB_REST_USERNAME=${USER}
fi
if [ -n "${PASSWORD}" ]; then
  export CB_REST_PASSWORD=${PASSWORD}
fi

init_cluster(){
    echo "Initializing cluster..."

    couchbase-cli cluster-init \
      --cluster="${fqdn}:${PORT}" \
      --cluster-username="${CB_REST_USERNAME}" \
      --cluster-password="${CB_REST_PASSWORD}" \
      --cluster-port="${PORT}" \
      --services="${SERVICES}" \
      --cluster-ramsize="${RAM_SIZE_MB}" \
      --cluster-index-ramsize="${INDEX_RAM_SIZE_MB}" \
      --cluster-fts-ramsize="${FTS_RAM_SIZE_MB}" \
      --index-storage-setting="${STORAGE_SETTING}"

    echo "Disabling update notifications..."

    couchbase-cli setting-notification \
      --cluster="${fqdn}:${PORT}" \
      --enable-notification="0"

    echo "Configuring cluster name..."

    couchbase-cli setting-cluster \
      --cluster="${fqdn}:${PORT}" \
      --cluster-name="${CLUSTER_NAME}"

    echo "Configuring auto failover..."

    couchbase-cli setting-autofailover \
      --cluster="${fqdn}:${PORT}" \
      --enable-auto-failover="${ENABLE_AUTO_FAILOVER}" \
      --auto-failover-timeout="${AUTO_FAILOVER_TIMEOUT}"
} 

set_node_hostname(){
    # set node hostname if fqdn contains a dot
    if [[ $fqdn == *.* ]] ; then
      echo "Setting node hostname..."

      couchbase-cli node-init \
        --cluster="${fqdn}:${PORT}" \
        --node-init-hostname=$fqdn
    fi
}

add_node_to_cluster(){
    echo "Waiting for cluster node to become available at ${APP_NAME}-discovery:${PORT} to join cluster..."
    until curl -s -o /dev/null "http://${APP_NAME}-discovery:${PORT}"; do
      sleep 1
    done;
    echo "Adding node $fqdn to cluster..."

    couchbase-cli server-add \
      --cluster="${APP_NAME}-discovery:${PORT}" \
      --server-add="${fqdn}:${PORT}" \
      --server-add-username="${USER}" \
      --server-add-password="${PASSWORD}" \
      --service="${SERVICES}"
}

rebalance_node_to_cluster(){
    echo "rebalancing cluster with new node $fqdn..."
    couchbase-cli rebalance \
      --cluster="${APP_NAME}-discovery:${PORT}"
}

recover_node_to_cluster(){
    echo "Gracefully failover..."
    couchbase-cli failover --cluster="${APP_NAME}-discovery:${PORT}" \
    --server-failover="${fqdn}:${PORT}" \
    --user="${CB_REST_USERNAME}" \
    --password="${CB_REST_PASSWORD}" || true
    
    echo "Recovering the node..."
    couchbase-cli recovery --cluster="${APP_NAME}-discovery:${PORT}" \
    --server-recovery="${fqdn}:${PORT}" \
    --recovery-type=full \
    --user="${CB_REST_USERNAME}" \
    --password="${CB_REST_PASSWORD}" || true

    echo "Rebalance the cluster..."  
    couchbase-cli rebalance --cluster="${APP_NAME}-discovery:${PORT}" \
    --user="${CB_REST_USERNAME}" \
    --password="${CB_REST_PASSWORD}" || true	
}

###############
#### Main #####

echo "Waiting for host $fqdn to become resolvable..."
until ping -c1 $fqdn &>/dev/null; do :; done

# start couchbase as background job
echo "Starting Couchbase server..."
/usr/sbin/runsvdir-start &

pid=$!

# wait for couchbase to become ready
echo "Waiting for Couchbase server $fqdn to become ready..."
until curl -s -o /dev/null "http://$fqdn:${PORT}"; do
  echo "curl -s -o /dev/null http://$fqdn:${PORT}"
  sleep 1
done;


echo "Is there a running cluster?..."
runningCluster="true"
if curl -s -o /dev/null --max-time 5 "http://${APP_NAME}-discovery:${PORT}"; then
  couchbase-cli server-list \
  --cluster="${APP_NAME}-discovery:${PORT}" \
  --user="${CB_REST_USERNAME}" \
  --password="${CB_REST_PASSWORD}" > cluster.txt || runningCluster="false"
else
  runningCluster="false"
fi

if [ "${runningCluster}" == "false" ]; then
    echo "No running cluster found..."
    initCluster="false"
    couchbase-cli server-list \
      --cluster="${fqdn}:${PORT}" \
      --user="${CB_REST_USERNAME}" \
      --password="${CB_REST_PASSWORD}" || initCluster="true"

    if [[ $initCluster == "true" ]]; then
      echo "creating the cluster for the very first time..."
      set_node_hostname
      init_cluster
    fi
else
  echo "Found a running cluster..."
  cat cluster.txt
  #check if the cluster busy with a rebalance
  RebalanceStatus=$(couchbase-cli rebalance-status --cluster="${APP_NAME}-discovery:${PORT}" -u ${USER} -p ${PASSWORD} | grep status | tr -s ' ' | cut -d: -f2 | cut -d'"' -f2)
  until [[ $RebalanceStatus != "running" ]]; do
    echo "the cluster busy with a rebalance..."
    sleep 1

    RebalanceStatus=$(couchbase-cli rebalance-status --cluster="${APP_NAME}-discovery:${PORT}" -u ${USER} -p ${PASSWORD} | grep status | tr -s ' ' | cut -d: -f2 | cut -d'"' -f2)
  done

  # Is this node been part of the cluster?
  partOfCluster=$(cat cluster.txt | grep $fqdn | wc -l)
  echo "I'm going to run a rebalance" > /doNotBeHealthy.txt
  if [[ $partOfCluster -eq 0 ]]; then
    echo "adding node $fqdn to the cluster and rebalance..."
    #if a node has a hostname already (beacuse it's kicked out of the cluster) avoid the failure with "|| true"
    set_node_hostname || true
    add_node_to_cluster
    rebalance_node_to_cluster
  else
    echo "failover, recovery, and rebalance the cluster..."
    recover_node_to_cluster 
  fi
fi

rm -f /doNotBeHealthy.txt
echo "Couchbase cluster:"
couchbase-cli server-list \
  --cluster="${fqdn}:${PORT}" \
  --user="${CB_REST_USERNAME}" \
  --password="${CB_REST_PASSWORD}"

echo "Running Couchbase server $fqdn..."
wait $pid
echo "Couchbase server has stopped, exiting..."