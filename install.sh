#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ ! -f `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed ]; then
  touch `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed
  source `dirname "${BASH_SOURCE[0]}"`/.util.sh

  travis_fold start install-$1
  echo "Installing $1"
  source `dirname "${BASH_SOURCE[0]}"`/tools/$1.sh
  travis_fold end install-$1
fi
