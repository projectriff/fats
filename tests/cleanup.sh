#!/bin/bash

set -o nounset

source `dirname "${BASH_SOURCE[0]}"`/../.util.sh

# attempt to cleanup riff and the cluster
fats_fold start system-uninstall
echo "Uninstall riff system"
duffle uninstall riff --credentials k8s || true
kubectl delete namespace $NAMESPACE || true
fats_fold end system-uninstall

source `dirname "${BASH_SOURCE[0]}"`/../cleanup.sh
