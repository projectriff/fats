#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

fats_dir=`dirname "${BASH_SOURCE[0]}"`/..

source $fats_dir/start.sh

# install tools
$fats_dir/install.sh riff
$fats_dir/install.sh helm

echo "Installing riff system"

source $fats_dir/macros/no-resource-requests.sh
source $fats_dir/macros/helm-init.sh

helm repo add projectriff https://projectriff.storage.googleapis.com/charts/releases
helm repo update

helm install projectriff/istio --name istio --namespace istio-system --devel --wait \
  --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}

helm install projectriff/riff --name riff --devel \
  --set riff.runtimes.core.enabled=true \
  --set riff.runtimes.knative.enabled=true \
  --set riff.runtimes.streaming.enabled=true --wait

source $fats_dir/macros/streaming-prereq-install.sh

# health checks
echo "Checking for ready ingress"
wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE

# run test functions
source `dirname "${BASH_SOURCE[0]}"`/../functions/helpers.sh

# in cluster builds
for test in java java-boot node npm command; do
  path=`dirname "${BASH_SOURCE[0]}"`/../functions/uppercase/${test}
  function_name=fats-cluster-uppercase-${test}
  image=$(fats_image_repo ${function_name})
  create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path functions/uppercase/${test}"
  input_data=fats
  expected_data=FATS
  runtime=core

  run_function $path $function_name $image "$create_args" $input_data $expected_data $runtime
done

# local builds
if [ "$machine" != "MinGw" ]; then
  # TODO enable for windows once we have a linux docker daemon available
  for test in java java-boot node npm command; do
    path=`dirname "${BASH_SOURCE[0]}"`/../functions/uppercase/${test}
    function_name=fats-local-uppercase-${test}
    image=$(fats_image_repo ${function_name})
    create_args="--local-path ."
    input_data=fats
    expected_data=FATS
    runtime=knative

    run_function $path $function_name $image "$create_args" $input_data $expected_data $runtime
  done
fi

# streaming functions
# for test in java-boot java; do
#   path=`dirname "${BASH_SOURCE[0]}"`/../functions/repeater/${test}
#   function_name=fats-cluster-repeater-${test}
#   image=$(fats_image_repo ${function_name})
#   create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path functions/repeater/${test}"
#   input_data='letters=two%numbers=2'
#   expected_data='[two, two]'
#   runtime=streaming

#   create_stream letters 'text/plain'
#   create_stream numbers 'application/json'
#   create_stream repeated 'application/json'

#   create_function $path $function_name $image "$create_args" "$input_data" "$expected_data" $runtime

#   processor_args="--input letters --input numbers --output repeated"
#   create_processor $function_name "$processor_args"

#   log_stream  repeated
#   post_stream letters two
#   post_stream numbers 2

#   verify_results repeated "$expected_data"

# done


# run application
source `dirname "${BASH_SOURCE[0]}"`/../applications/helpers.sh

for test in java-boot node; do
  path=`dirname "${BASH_SOURCE[0]}"`/../applications/uppercase/${test}
  application_name=fats-application-uppercase-${test}
  image=$(fats_image_repo ${application_name})
  create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path applications/uppercase/${test}"
  input_data="application"
  expected_data=APPLICATION
  runtime=core

  run_application $path $application_name $image "$create_args" "$input_data" $expected_data $runtime
done
