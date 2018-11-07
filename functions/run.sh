#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`

source $dir/helpers.sh

for test in uppercase; do
  echo "Current function scenario: $test"
  source $dir/$test/run.sh
done
