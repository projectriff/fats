#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`

source $dir/util.sh
source $dir/init.sh $CLUSTER

source $dir/functions/run.sh
source $dir/channels/run.sh
