#!/bin/bash

counter=0
total=50

green='\033[0;32m'
reset='\033[0m'

while [ $counter -lt $total ]; do

    kubectl cordon edge-node
    kubectl drain edge-node --ignore-daemonsets
    kubectl delete node edge-node 

    sudo systemctl stop feather
    kubectl exec -n keylime hhkl-keylime-tenant-5b7475b575-bfs5m -it -- keylime_tenant -c delete -u d432fbb3-d2f1-4a97-9ef7-75bd81c00000
    helm uninstall edgenode -n keylime 

    helm install edgenode /home/jordi/projects/deploy-edgenode/ -n keylime
    sudo systemctl restart keylime_agent

    sleep 25

    keylime_start_time=$(systemctl show -p ActiveEnterTimestamp keylime_agent.service | cut -d= -f2)
    fledge_start_time=$(systemctl show -p ActiveEnterTimestamp feather.service | cut -d= -f2)

    sudo systemctl status feather >> status_reports/fledge_status_$counter
    sudo systemctl status keylime_agent >> status_reports/keylime_status_$counter


    time_difference=$(( $(date -d"$fledge_start_time" +%s) - $(date -d"$keylime_start_time" +%s) ))

    echo $time_difference >> result
    echo -e "${green}Done $((counter + 1))/$total. Time difference: $time_difference.${reset}\n"

    ((counter++))

done
