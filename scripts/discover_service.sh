#!/bin/bash
KUBECTL=kubectl

if [[ $# < 2 || "$1" == "-h" ]]
    then
    echo discoverService SERVICENAME INTERNALPORT
    exit -1
fi

SERVICENAME=$1
INTERNALPORT=$2

EXTPORT=$(${KUBECTL} get svc $SERVICENAME -o=jsonpath="{.spec.ports[?(@.port==${INTERNALPORT})].nodePort}")
EXTIP=$(${KUBECTL} get node -o=jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

if [[ -z $EXTPORT ]]
    then
    echo -e "ERROR: service=$SERVICENAME internal-port=$INTERNALPORT not found.\n"
    exit -2
elif [[ -z $EXTIP ]]
    then
    echo -e "ERROR: could not retrieve underlying node IPs.\n"
    exit -2
fi

echo 'http://'$EXTIP:$EXTPORT
