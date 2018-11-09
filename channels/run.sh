#!/bin/bash

service_name='correlator'

# install correlator
riff service create $service_name --image projectriff/correlator:fats --namespace $NAMESPACE

# wait for correlator to deploy
selector="serving.knative.dev/service=$service_name"
fats_echo "Waiting for deployment labeled with $selector to be created:"
wait_kube_selector_exists 'deployment.extensions' "$selector" "$NAMESPACE" "$service_name"

# patch the cpu request for the correlator so a function can start even if the available cpu is low
deployment="$(kubectl get deployment --namespace $NAMESPACE -l $selector -oname)"
fats_echo "Patching cpu request for $deployment"
kubectl patch $deployment --namespace $NAMESPACE --patch "$(cat ./cpu-patch.yaml)"

# wait for correlator service to be ready
fats_echo "Waiting for $service_name to become ready:"
wait_kservice_ready "${service_name}" $NAMESPACE

for test in correlated; do
  echo "Current eventing scenario: $test"
  source `dirname "${BASH_SOURCE[0]}"`/$test/run.sh $service_name
done

# cleanup correlator
riff service delete $service_name --namespace $NAMESPACE
