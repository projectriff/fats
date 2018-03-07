#!/bin/bash

source ./util.sh

dir=`dirname "${BASH_SOURCE[0]}"`

for test in uppercase; do
    source $dir/$test/run.sh
done
