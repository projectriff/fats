#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

travis_fold start cleanup-registry
echo "Cleanup registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/cleanup.sh
travis_fold end cleanup-registry

travis_fold start cleanup-cluster
echo "Cleanup cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/cleanup.sh
travis_fold end cleanup-cluster
