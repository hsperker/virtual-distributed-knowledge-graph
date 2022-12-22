#!/bin/bash
set -e

export TRINO_NODE_ID=$(uuidgen)
echo "TRINO_NODE_ID=$TRINO_NODE_ID"
envsubst < /tmp/trino.node.properties.template > /etc/trino/node.properties

export TRINO_DISCOVERY_URI=${TRINO_DISCOVERY_URI:-http://localhost:8080}

if [[ $TRINO_NODE_TYPE == "coordinator" ]]; then
    echo "Configuring a coordinator Trino node"
    envsubst < /tmp/coordinator.config.properties.template > /etc/trino/config.properties
elif [[ $TRINO_NODE_TYPE == "worker" ]]; then
    echo "Configuring a worker Trino node"
    envsubst < /tmp/worker.config.properties.template > /etc/trino/config.properties
else 
    printf '%s\n' "Invalid TRINO_NODE_TYPE parameter: $TRINO_NODE_TYPE" >&2
    exit 1
fi

chown -R trino:trino /etc/trino

/usr/lib/trino/bin/run-trino