#!/bin/bash

service_name='correlator'

# install correlator
riff service create $service_name --image projectriff/correlator:fats --namespace $NAMESPACE

# wait for correlator to deploy
fats_echo "Waiting for $service_name to become ready:"
wait_kservice_ready "${service_name}" $NAMESPACE

for test in correlated-hello; do
  echo "Current eventing scenario: $test"
  source `dirname "${BASH_SOURCE[0]}"`/$test/run.sh $service_name
done

# cleanup correlator
riff service delete $service_name --namespace $NAMESPACE
