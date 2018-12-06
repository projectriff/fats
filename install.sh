#!/bin/bash

if [ ! -f `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed ]; then
  echo "Installing $1"
  source `dirname "${BASH_SOURCE[0]}"`/tools/$1.sh
  touch `dirname "${BASH_SOURCE[0]}"`/tools/$1.installed
fi
