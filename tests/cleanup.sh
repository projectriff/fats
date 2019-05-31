#!/bin/bash

set -o nounset

source `dirname "${BASH_SOURCE[0]}"`/../.util.sh

# script failed, dump debug info
if [ "$TRAVIS_TEST_RESULT" = "1" ]; then
  travis_fold start debug
  echo "Debug logs"
  sudo free -m -t
  sudo dmesg
  travis_fold end debug
fi

# attempt to cleanup riff and the cluster
travis_fold start system-uninstall
echo "Uninstall riff system"
duffle uninstall myriff || true
kubectl delete namespace $NAMESPACE || true
travis_fold end system-uninstall

source `dirname "${BASH_SOURCE[0]}"`/../cleanup.sh
