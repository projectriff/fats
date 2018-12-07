#!/bin/bash

set -o nounset

# script failed, dump debug info
if [ "$TRAVIS_TEST_RESULT" = "1" ]; then
  sudo free -m -t
  sudo dmesg
fi

# attempt to cleanup riff and the cluster
riff system uninstall --istio --force || true
kubectl delete namespace $NAMESPACE || true

source `dirname "${BASH_SOURCE[0]}"`/../cleanup.sh
