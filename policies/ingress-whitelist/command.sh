#!/bin/bash

if [ -z "$1" ]; then
    echo "kube-context need to be passed as argument"
    exit 1
fi

K="kubectl --context=${1}"

COMMANDS=(install test-valid test-invalid uninstall quit)
PS3="Your choice: "
while true; do
    select COMMAND in "${COMMANDS[@]}";
        do
        case $COMMAND in
                "quit")
                echo "Exiting."
                break
                ;;
                "install")
                    ${K} create configmap ingress-whitelist --from-file=ingress-whitelist.rego
                    ${K} create configmap ingress-conflicts --from-file=ingress-conflicts.rego
                    ${K} create -f qa-namespace.yaml
                    ${K} create -f production-namespace.yaml
                    ${K} create -f staging-namespace.yaml
                    break
                ;;
                "test-valid")
                    ${K} create -f ingress-ok.yaml -n production
                    read -p "Press [Enter] key to continue..."
                    break
                ;;
                "test-invalid")
                    ${K} create -f ingress-bad.yaml -n qa
                    read -p "Press [Enter] key to continue..."
                    ${K} create -f ingress-ok.yaml -n staging
                    read -p "Press [Enter] key to continue..."
                    break
                ;;
                "uninstall")
                    ${K} delete -f qa-namespace.yaml
                    ${K} delete -f production-namespace.yaml
                    ${K} delete configmap ingress-whitelist
                    break
                ;;
                *)
                    echo "Wrong choice"
                    break
                ;;
        esac
    done
    if [[ "${COMMAND}" = "quit" ]]; then
        break
    fi
done