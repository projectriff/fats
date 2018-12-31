#!/bin/bash

`dirname "${BASH_SOURCE[0]}"`/.util.sh

if [ ! -f `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed ]; then
  travis_fold start install-$1
  echo "Installing $1"
  `dirname "${BASH_SOURCE[0]}"`/tools/$1.sh
  touch `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed
  travis_fold end install-$1
fi
