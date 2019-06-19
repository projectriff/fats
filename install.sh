#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ ! -f `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed ]; then
  touch `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed
  source `dirname "${BASH_SOURCE[0]}"`/.util.sh

  echo "Installing $1"
  source `dirname "${BASH_SOURCE[0]}"`/tools/$1.sh ${@:2}
fi
