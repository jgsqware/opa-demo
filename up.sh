#!/bin/bash

if [ -z "$1" ]; then
    echo "kube-context need to be passed as argument"
    exit 1
fi

K="kubectl --context=${1}"

${K} create namespace opa
kubectl config set-context "${1}" --namespace=opa

mkdir -p ./certs

(
    cd ./certs || exit

    if [ ! -f "ca.key" ]; then
        openssl genrsa -out ca.key 2048
    fi

    if [ ! -f "ca.crt" ]; then
        openssl req -x509 -new -nodes -key ca.key -days 100000 -out ca.crt -subj "/CN=admission_ca"
    fi

    if [ ! -f "server.conf" ]; then
        cat >server.conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOF
    fi

    if [ ! -f "server.key" ]; then
        openssl genrsa -out server.key 2048
    fi

    if [ ! -f " server.csr" ]; then
            openssl req -new -key server.key -out server.csr -subj "/CN=opa.opa.svc" -config server.conf
    fi

    if [ ! -f "server.crt" ]; then
        openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 100000 -extensions v3_req -extfile server.conf
    fi

)

${K} create secret tls opa-server --cert=./certs/server.crt --key=./certs/server.key

${K} apply -f ./yaml

${K} label ns kube-system openpolicyagent.org/webhook=ignore
${K} label ns opa openpolicyagent.org/webhook=ignore

sed "s/--REPLACE--/$(cat ./certs/ca.crt | base64 | tr -d '\n')/g" ./opa-conf/webhook-configuration.yaml  | ${K} apply -f -

