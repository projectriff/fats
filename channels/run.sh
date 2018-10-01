#!/bin/bash

service_name='correlator'

# install correlator
riff service create $service_name --image projectriff/correlator:fats

# wait for correlator to deploy
fats_echo "Waiting for $service_name to become ready:"
  until kube_ready \
  'services.serving.knative.dev' \
  'default' \
  "${service_name}" \
  ';{range @.status.conditions[*]}{@.type}={@.status};{end}' \
  ';Ready=True;' \
; do sleep 1; done


for test in correlated-hello; do
  dir=`dirname "${BASH_SOURCE[0]}"`
  echo "Current eventing scenario: $test"
  source $dir/$test/run.sh $service_name
done

# cleanup correlator
riff service delete $service_name
