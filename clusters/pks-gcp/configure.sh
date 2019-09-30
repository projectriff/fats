#!/bin/bash

if [ -z ${TOOLSMITH_ENV+x} ]; then
  # load Azure Pipelines secure file
  echo "Creating TOOLSMITH_ENV from ${DOWNLOADSECUREFILE_SECUREFILEPATH}"
  export TOOLSMITH_ENV=$(cat "${DOWNLOADSECUREFILE_SECUREFILEPATH}" | openssl base64 -a -A)
fi

# Install pks cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh pks

export K8S_SERVICE_TYPE=LoadBalancer

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}

post_registry_start() {
  local registry=$1

  # nothing to do
}
