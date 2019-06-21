#!/bin/bash

set -o nounset

source `dirname "${BASH_SOURCE[0]}"`/../.util.sh

# attempt to cleanup riff and the cluster
echo "Uninstall riff system"
duffle_k8s_service_account=${duffle_k8s_service_account:-duffle-runtime}
duffle_k8s_namespace=${duffle_k8s_namespace:-kube-system}
SERVICE_ACCOUNT=${duffle_k8s_service_account} KUBE_NAMESPACE=${duffle_k8s_namespace} duffle uninstall riff -d k8s || true
kubectl delete namespace $NAMESPACE || true

source `dirname "${BASH_SOURCE[0]}"`/../cleanup.sh
