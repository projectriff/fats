#!/bin/bash

source ./util.sh

gcloud container clusters delete $CLUSTER_NAME --quiet
