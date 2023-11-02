#!/bin/bash

kubectl delete configmap services
kubectl delete -f scanjob.yaml

kubectl get svc -A -o json |\
jq -r '.items[] | select(.metadata.namespace | startswith("openshift-"))  |  select(.spec.ports!=null) | . as $svc | .spec.ports[] | select(.protocol=="TCP") | .port | tostring |  $svc.metadata.name + "." + $svc.metadata.namespace + ".svc.cluster.local" + ":" + . ' |\
kubectl create configmap services --from-file=services=/dev/stdin

kubectl create -f scanjob.yaml
kubectl wait job/testssl --for=jsonpath=.status.ready=1

kubectl exec -n default -it job/testssl -- testssl.sh  --quiet --file /input/services --mode  parallel --connect-timeout 5  --openssl-timeout 5 --each-cipher --show-each --jsonfile /tmp/output
#Copy out all the jsons.

mkdir -p output
kubectl exec job/testssl -- tar -cf - -C /tmp/output . | tar -xf - -C output
