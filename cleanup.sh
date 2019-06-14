#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

fats_fold start cleanup-registry
echo "Cleanup registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/cleanup.sh
fats_fold end cleanup-registry

fats_fold start cleanup-cluster
echo "Cleanup cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/cleanup.sh
fats_fold end cleanup-cluster
