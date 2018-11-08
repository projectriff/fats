#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/helpers.sh

for test in uppercase; do
  echo "Current function scenario: $test"
  source `dirname "${BASH_SOURCE[0]}"`/$test/run.sh
done
