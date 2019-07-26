# K8S-Couchbase-6.0-Community
Run Couchbase 6.0 Community on Kubernetes

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