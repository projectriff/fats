#!/bin/bash

set -o nounset

source `dirname "${BASH_SOURCE[0]}"`/../.util.sh

# attempt to cleanup riff and the cluster
echo "Uninstall riff system"
duffle uninstall riff --credentials k8s || true
kubectl delete namespace $NAMESPACE || true

source `dirname "${BASH_SOURCE[0]}"`/../cleanup.sh
