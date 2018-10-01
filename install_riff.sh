#!/bin/bash

source ./util.sh
source ./init.sh $CLUSTER

go get github.com/projectriff/riff

riff system install $SYSTEM_INSTALL_FLAGS
fats_create_push_credentials default
riff namespace init default --secret push-credentials

# health checks
echo "Checking for ready pods"
until pod_query_ready 'knative=ingressgateway' 'istio-system'; do sleep 1; done
until pod_query_ready 'app=controller' 'knative-serving'; do sleep 1; done
until pod_query_ready 'app=build-controller' 'knative-build'; do sleep 1; done
until pod_query_ready 'app=eventing-controller' 'knative-eventing'; do sleep 1; done
until pod_query_ready 'clusterBus=stub' 'knative-eventing'; do sleep 1; done
