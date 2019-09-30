#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

echo "Starting cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/start.sh

echo "Starting registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/start.sh

post_registry_start $REGISTRY
