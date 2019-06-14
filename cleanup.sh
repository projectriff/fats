#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

echo "Cleanup registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/cleanup.sh

echo "Cleanup cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/cleanup.sh
