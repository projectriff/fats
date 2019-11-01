#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

fats_dir=`dirname "${BASH_SOURCE[0]}"`/../..

source $fats_dir/start.sh

# install tools
$fats_dir/install.sh riff
$fats_dir/install.sh helm

echo "Installing riff system"

source $fats_dir/macros/helm-init.sh
helm repo add projectriff https://projectriff.storage.googleapis.com/charts/releases
helm repo update

helm install projectriff/cert-manager --name cert-manager --devel --wait
sleep 5
wait_pod_selector_ready app=cert-manager cert-manager
wait_pod_selector_ready app=webhook cert-manager

source $fats_dir/macros/no-resource-requests.sh

helm install projectriff/istio --name istio --namespace istio-system --devel --wait \
  --set gateways.istio-ingressgateway.type=${K8S_SERVICE_TYPE}
helm install projectriff/riff --name riff --devel --wait \
  --set cert-manager.enabled=false \
  --set tags.core-runtime=true \
  --set tags.knative-runtime=true

# health checks
echo "Checking for ready ingress"
wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE

# run test functions
source $fats_dir/functions/helpers.sh

# in cluster builds
# workaround for https://github.com/projectriff/node-function-invoker/issues/113
if [ $CLUSTER = "pks-gcp" ]; then
  languages="java java-boot command"
else
  languages="java java-boot node npm command"
fi
for test in $languages; do
  path=$fats_dir/functions/uppercase/${test}
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
  for test in $languages; do
    path=$fats_dir/functions/uppercase/${test}
    function_name=fats-local-uppercase-${test}
    image=$(fats_image_repo ${function_name})
    create_args="--local-path ."
    input_data=fats
    expected_data=FATS
    runtime=knative

    run_function $path $function_name $image "$create_args" $input_data $expected_data $runtime
  done
fi

# run application
source $fats_dir/applications/helpers.sh

for test in java-boot node; do
  path=$fats_dir/applications/uppercase/${test}
  application_name=fats-application-uppercase-${test}
  image=$(fats_image_repo ${application_name})
  create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path applications/uppercase/${test}"
  input_data="application"
  expected_data=APPLICATION
  runtime=core

  run_application $path $application_name $image "$create_args" "$input_data" $expected_data $runtime
done
