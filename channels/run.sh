#!/bin/bash

source ./util.sh
source ./init.sh $CLUSTER

for test in correlated-hello; do
  dir=`dirname "${BASH_SOURCE[0]}"`
  echo "Current eventing scenario: $test"
  source $dir/$test/run.sh
done