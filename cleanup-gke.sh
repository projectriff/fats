#!/bin/bash

source ./util.sh

gcloud container clusters delete $CLUSTER_NAME
gcloud compute firewall-rules list --filter $CLUSTER_NAME --format="table(name)" | \
  tail -n +2 | \
  xargs --no-run-if-empty gcloud compute firewall-rules delete
