#!/bin/bash

source ./util.sh
source ./init.sh $CLUSTER

go get github.com/projectriff/riff

riff system install $SYSTEM_INSTALL_FLAGS
fats_create_push_credentials $NAMESPACE
riff namespace init $NAMESPACE --secret push-credentials

# health checks
echo "Checking for ready pods"
wait_pod_selector_ready 'knative=ingressgateway' 'istio-system'
wait_pod_selector_ready 'app=controller' 'knative-serving'
wait_pod_selector_ready 'app=build-controller' 'knative-build'
wait_pod_selector_ready 'app=eventing-controller' 'knative-eventing'
wait_pod_selector_ready 'clusterBus=stub' 'knative-eventing'
