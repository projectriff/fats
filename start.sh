#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

fats_fold start start-cluster
echo "Starting cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/start.sh
fats_fold end start-cluster

fats_fold start start-registry
echo "Starting registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/start.sh
fats_fold end start-registry
