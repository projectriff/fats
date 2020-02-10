#!/bin/bash

if [ -z "${CI:-}" ] && [ -z "${GITHUB_WORKSPACE:-}" ]; then
  echo "FATS start is only supported in CI environments"
  exit 1
fi

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

echo "##[group]Starting cluster $CLUSTER"
source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/start.sh
echo "##[endgroup]"

echo "##[group]Starting registry $REGISTRY"
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/start.sh
post_registry_start $REGISTRY
echo "##[endgroup]"
