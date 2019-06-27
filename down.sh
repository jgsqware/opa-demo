#!/bin/bash

if [ -z "$1" ]; then
    echo "kube-context need to be passed as argument"
    exit 1
fi

K="kubectl --context=${1}"

kubectl config set-context "${1}" --namespace=opa

rm -rf ./certs

${K} delete configmap ingress-whitelist 

${K} delete -f ./opa-conf/webhook-configuration.yaml

${K} label ns kube-system openpolicyagent.org/webhook-
${K} label ns opa openpolicyagent.org/webhook-

${K} delete -f ./yaml

${K} delete secret opa-server

${K} delete namespace opa

