#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.util.sh

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

travis_fold start start-cluster
echo "Starting cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/start.sh
travis_fold end start-cluster

travis_fold start start-registry
echo "Starting registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/start.sh
travis_fold end start-registry
