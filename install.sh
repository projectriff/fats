#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

perform_install() {
  if [ ! -f `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed ]; then
    touch `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed
    source `dirname "${BASH_SOURCE[0]}"`/.util.sh

    echo "Installing $1"
    source `dirname "${BASH_SOURCE[0]}"`/tools/$1.sh "${2:-}" "${3:-}"
  fi
}

if [ "${SKIP_INSTALLED:-x}" == "true" ] && [ -x "$(command -v $1)" ]; then
  echo "$1 already installed skipping"
else
  perform_install "$@"
fi
