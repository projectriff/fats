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

# in cluster builds
# workaround for https://github.com/projectriff/node-function-invoker/issues/113
if [ $CLUSTER = "pks-gcp" ]; then
  languages="java java-boot command"
else
  languages="java java-boot node npm command"
fi
for test in $languages; do
  name=fats-cluster-uppercase-${test}
  image=$(fats_image_repo ${name})
  create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path functions/uppercase/${test}"

  echo "##[group]Run function $name"

  riff function create $name $args --image $image --namespace $NAMESPACE --tail &
  riff core deployer create $name --function-ref $name --namespace $NAMESPACE --tail

  source $fats_dir/macros/invoke_core_deployer.sh $name "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS

  riff core deployer delete $name --namespace $NAMESPACE
  riff function delete $name --namespace $NAMESPACE
  fats_delete_image $image

  echo "##[endgroup]"
done

# local builds
if [ "$machine" != "MinGw" ]; then
  # TODO enable for windows once we have a linux docker daemon available
  for test in $languages; do
    name=fats-local-uppercase-${test}
    image=$(fats_image_repo ${name})
    create_args="--local-path $fats_dir/functions/uppercase/${test}"

    echo "##[group]Run function $name"

    riff function create $name $args --image $image --namespace $NAMESPACE --tail &
    riff knative deployer create $name --function-ref $name --namespace $NAMESPACE --tail

    source $fats_dir/macros/invoke_knative_deployer.sh $name "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS

    riff knative deployer delete $name --namespace $NAMESPACE
    riff function delete $name --namespace $NAMESPACE
    fats_delete_image $image

    echo "##[endgroup]"
  done
fi

for test in java-boot node; do
  name=fats-application-uppercase-${test}
  image=$(fats_image_repo ${name})
  create_args="--git-repo $(git remote get-url origin) --git-revision $(git rev-parse HEAD) --sub-path applications/uppercase/${test}"

  echo "##[group]Run application $name"

  riff application create $name $args --image $image --namespace $NAMESPACE --tail &
  riff core deployer create $name --application-ref $name --namespace $NAMESPACE --tail

  source $fats_dir/macros/invoke_core_deployer.sh $name "--get --data-urlencode input=fats" FATS

  riff core deployer delete $name --namespace $NAMESPACE
  riff application delete $name --namespace $NAMESPACE
  fats_delete_image $image

  echo "##[endgroup]"
done
