#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

`dirname "${BASH_SOURCE[0]}"`/../install.sh kubectl
`dirname "${BASH_SOURCE[0]}"`/../install.sh kail

source `dirname "${BASH_SOURCE[0]}"`/../start.sh

# install riff
`dirname "${BASH_SOURCE[0]}"`/../install.sh riff
`dirname "${BASH_SOURCE[0]}"`/../install.sh duffle

travis_fold start system-install
echo "Installing riff system"

cat <<EOF | > myk8s.yaml
name: myk8s
credentials:
- name: kubeconfig
  source:
    path: $HOME/.kube/config
EOF
duffle credentials add myk8s.yaml
curl -O https://storage.googleapis.com/projectriff/riff-cnab/snapshots/riff-bundle-latest.json
duffle install myriff riff-bundle-latest.json --bundle-is-file --credentials myk8s --insecure

# health checks
echo "Checking for ready ingress"
wait_for_ingress_ready 'istio-ingressgateway' 'istio-system'

# setup namespace
kubectl create namespace $NAMESPACE
fats_create_push_credentials $NAMESPACE

travis_fold end system-install

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
