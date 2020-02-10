#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${CI:-}" ] && [ -z "${GITHUB_WORKSPACE:-}" ]; then
  echo "FATS install is only supported in CI environments"
  exit 1
fi

if [ -f `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed ]; then
  # tool previously installed
  exit 0
fi

touch `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed
source `dirname "${BASH_SOURCE[0]}"`/.util.sh

echo "Installing $1"
source `dirname "${BASH_SOURCE[0]}"`/tools/$1.sh "${2:-}" "${3:-}"
