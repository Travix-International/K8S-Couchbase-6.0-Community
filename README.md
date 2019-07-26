# K8S-Couchbase-6.0-Community
Run Couchbase 6.0 Community on Kubernetes

# Deploy it manually to your K8S cluster
 
    git clone git@github.com:Travix-International/K8S-Couchbase-6.0-Community.git

    cd K8S-Couchbase-6.0-Community

    docker container run --rm -it --env-file ./env.list \
    -v (pwd):/wd bhgedigital/envsubst \
    sh -c "envsubst < /wd/kubernetes.tmpl.yaml > kubernetes-subst.yaml && cat kubernetes-subst.yaml"