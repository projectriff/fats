#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh
source `dirname "${BASH_SOURCE[0]}"`/init.sh $CLUSTER

source `dirname "${BASH_SOURCE[0]}"`/functions/run.sh
source `dirname "${BASH_SOURCE[0]}"`/channels/run.sh
