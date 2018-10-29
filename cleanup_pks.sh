#!/bin/bash

source ./util.sh

pks delete-cluster ${TS_G_ENV}-${CLUSTER_NAME} --non-interactive --wait
