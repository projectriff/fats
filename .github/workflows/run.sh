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
  --set tags.knative-runtime=true \
  --set tags.streaming-runtime=true

# health checks
echo "Checking for ready ingress"
wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE

echo "##[group]Install streaming prerequisites"
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm install --name my-kafka incubator/kafka --set replicas=1,zookeeper.replicaCount=1,zookeeper.env.ZK_HEAP_SIZE=128m --namespace $NAMESPACE

riff streaming kafka-provider create franz --bootstrap-servers my-kafka:9092 --namespace $NAMESPACE

kubectl apply -f https://storage.googleapis.com/projectriff/riff-http-gateway/riff-http-gateway-0.5.0-snapshot.yaml
echo "##[endgroup]"

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

# streaming functions
for test in java-boot; do
  path=$fats_dir/functions/streaming-uppercase/${test}
  function_name=fats-cluster-streaming-uppercase-${test}
  image=$(fats_image_repo ${function_name})
  create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path functions/streaming-uppercase/${test}"
  runtime=streaming

  stringin="stringin-$test"
  stringout="stringout-$test"
  create_stream $stringin 'text/plain'
  create_stream $stringout 'text/plain'

  echo "##[group]Creating function $function_name"
  create_function $path $function_name $image "$create_args"
  echo "##[endgroup]"

  processor_args="--input $stringin --output $stringout"
  create_processor $function_name "$processor_args"

  log_stream $stringout
  post_stream $stringin foo "text/plain"
  post_stream $stringin bar "text/plain"

  expected_data="${NAMESPACE}_${stringout}: FOO${NAMESPACE}_${stringout}: BAR"

  verify_results "function" $stringout "$expected_data"
done

cleanup_portfwd

echo "##[group]Uninstall streaming prerequisites"
helm delete --purge my-kafka

riff streaming kafka-provider delete franz --namespace $NAMESPACE

kubectl delete -f https://storage.googleapis.com/projectriff/riff-http-gateway/riff-http-gateway-0.5.0-snapshot.yaml
echo "##[endgroup]"
