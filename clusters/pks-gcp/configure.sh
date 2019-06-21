#!/bin/bash

if [ -z ${TOOLSMITH_ENV+x} ]; then
  # load Azure Pipelines secure file
  echo "Creating TOOLSMITH_ENV from ${DOWNLOADSECUREFILE_SECUREFILEPATH}"
  export TOOLSMITH_ENV=$(cat "${DOWNLOADSECUREFILE_SECUREFILEPATH}" | openssl base64 -a -A)
fi

# Install pks cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh pks

export DUFFLE_RIFF_INSTALL_FLAGS="${DUFFLE_RIFF_INSTALL_FLAGS:-} -s node_port=false"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}
