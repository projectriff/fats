#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source `dirname "${BASH_SOURCE[0]}"`/../start.sh

# install tools
`dirname "${BASH_SOURCE[0]}"`/../install.sh riff
`dirname "${BASH_SOURCE[0]}"`/../install.sh duffle

echo "Installing riff system"

duffle_k8s_service_account=${duffle_k8s_service_account:-duffle-runtime}
duffle_k8s_namespace=${duffle_k8s_namespace:-kube-system}

kubectl create serviceaccount "${duffle_k8s_service_account}" -n "${duffle_k8s_namespace}"
kubectl create clusterrolebinding "${duffle_k8s_service_account}-cluster-admin" --clusterrole cluster-admin --serviceaccount "${duffle_k8s_namespace}:${duffle_k8s_service_account}"

duffle_opts=${duffle_opts:-}
if [[ $K8S_SERVICE_TYPE == "NodePort" ]]; then
  duffle_opts="${duffle_opts} -s node_port=true"
else
  duffle_opts="${duffle_opts} -s node_port=false"
fi

curl -O https://storage.googleapis.com/projectriff/riff-cnab/snapshots/riff-bundle-latest.json
SERVICE_ACCOUNT=${duffle_k8s_service_account} KUBE_NAMESPACE=${duffle_k8s_namespace} duffle install riff riff-bundle-latest.json --bundle-is-file ${duffle_opts} -d k8s

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

  run_function $path $function_name $image "$create_args" $input_data $expected_data
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

    run_function $path $function_name $image "$create_args" $input_data $expected_data
  done
fi
