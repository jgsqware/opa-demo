#!/bin/bash
if [ -z "$1" ]; then
    echo "kube-context need to be passed as argument"
    exit 1
fi

K="kubectl --context=${1}"


echo "This script can make any of the files in this directory private."
echo "Enter the number of the file you want to protect:"

PS3="Your choice: "
QUIT="Quit"
LOG="OPA log"
touch "./policies/$QUIT"
touch "./policies/$LOG"

while true; do
    select POLICY in ./policies/*;
        do
        case $POLICY in
                "./policies/$QUIT")
                echo "Exiting."
                break
                ;;
                "./policies/$LOG")
                ${K} logs -l app=opa -c opa -f
                break
                ;;
                *)
                    if [ -n "${POLICY}" ]; then
                        if [ -f "${POLICY}/command.sh" ]; then 
                            (
                                cd "${POLICY}" || exit
                                ./command.sh "${1}"
                            )
                        else
                            echo "${POLICY}/command.sh is no present."
                        fi
                    else 
                        echo "Wrong choice"
                    fi
                    break
                ;;
        esac
    done

    if [[ "${POLICY}" = "./policies/$QUIT" ]]; then
        break
    fi
done
rm "./policies/$QUIT"
rm "./policies/$LOG"

