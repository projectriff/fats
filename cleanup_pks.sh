#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`

source $dir/util.sh

# TODO uncomment if we use a PKS cluster per job
# pks delete-cluster ${TS_G_ENV}-${CLUSTER_NAME} --non-interactive --wait
