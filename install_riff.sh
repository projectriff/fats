#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh
source `dirname "${BASH_SOURCE[0]}"`/init.sh $CLUSTER

go get github.com/projectriff/riff

riff system install $SYSTEM_INSTALL_FLAGS

# health checks
echo "Checking for ready pods"
wait_pod_selector_ready 'knative=ingressgateway' 'istio-system'
wait_pod_selector_ready 'app=controller' 'knative-serving'
wait_pod_selector_ready 'app=webhook' 'knative-serving'
wait_pod_selector_ready 'app=build-controller' 'knative-build'
wait_pod_selector_ready 'app=build-webhook' 'knative-build'
wait_pod_selector_ready 'app=eventing-controller' 'knative-eventing'
wait_pod_selector_ready 'app=webhook' 'knative-eventing'
wait_pod_selector_ready 'clusterBus=stub' 'knative-eventing'
echo "Checking for ready ingress"
wait_for_ingress_ready 'knative-ingressgateway' 'istio-system'

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE
riff namespace init $NAMESPACE $NAMESPACE_INIT_FLAGS
