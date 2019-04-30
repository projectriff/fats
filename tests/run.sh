#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

`dirname "${BASH_SOURCE[0]}"`/../install.sh kubectl
`dirname "${BASH_SOURCE[0]}"`/../install.sh kail

source `dirname "${BASH_SOURCE[0]}"`/../start.sh

# install riff
`dirname "${BASH_SOURCE[0]}"`/../install.sh riff

travis_fold start system-install
echo "Installing riff system"

riff system install $SYSTEM_INSTALL_FLAGS

source `dirname "${BASH_SOURCE[0]}"`/run-tests.sh
