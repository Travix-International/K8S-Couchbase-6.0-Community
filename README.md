# K8S-Couchbase-6.0-Community
Run Couchbase 6.0 Community on Kubernetes

# Deploy it manually to your local machine

    docker run -p 8091:8091  \
    -e "USER=Administrator" \
    -e "PASSWORD=abc@123" \
    -e "AUTOFAILOVER_TIMEOUT=60" \
    -e "DISCOVERY_SERVICE=couchbase-0.local" \
    -e "FTS_RAM_SIZE_MB=256" \
    -e "INDEX_RAM_SIZE_MB=256" \
    -e "APP_NAME=couchbase" \
    -e "RAM_SIZE_MB=1024" \
    -e "REBALANCE_ON_NODE_ADDITION=1" \
    -e "SERVICES=data,index,query,fts" \
    travix/k8s-couchbase-6.0-community

Wait till you see "Running Couchbase server ..."

Then go to your browser and visit: http://127.0.0.1:8091/
 Username: Administrator, Password: abc@123
# Deploy it manually to your K8S cluster
 
    git clone git@github.com:Travix-International/K8S-Couchbase-6.0-Community.git

    cd K8S-Couchbase-6.0-Community

    docker run --rm -it --env-file ./env.list \
    -v (pwd):/wd bhgedigital/envsubst \
    sh -c "envsubst < /wd/kubernetes.tmpl.yaml > kubernetes-subst.yaml && cat kubernetes-subst.yaml" | \
    kubectl apply --dry-run  -f -
# Login to the UI

    http://<couchbase-v6-discovery-IP>:8091/ui/index.html
    Username: Administrator
    Password: wPT9VmGgacq8KAwxWGnDQ83m

## Best Practice
[Top 10 Things SysAdmin Must Know About Couchbase](https://blog.couchbase.com/top-10-things-ops-sys-admin-must-know-about-couchbase/)