#!/bin/bash

source ./util.sh
source ./init.sh $CLUSTER

# TODO: move hello out of functions
for test in hello uppercase; do
  dir=`dirname "${BASH_SOURCE[0]}"`
  echo "Current value: $test"
  source $dir/$test/run.sh
done