#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

fats_setup_gcloud

# delete orphaned resources

cluster_prefix=${1:-fats}
before=`date -v-1d -u +%Y-%m-%dT%H:%M:%SZ` # yesterday

gcloud container clusters list --filter="name ~ ^$cluster_prefix- AND createTime < $before" --format="table[no-heading](name)" | \
  xargs --no-run-if-empty gcloud container clusters delete

gcloud compute target-pools list --filter="createTime < $before" --format="table[no-heading](name, region)" | \
  sed 's/ / --region /2' | \
  xargs --no-run-if-empty gcloud compute target-pools delete

gcloud compute firewall-rules list --filter="name ~ ^gke-$cluster_prefix- AND createTime < $before" --format="table[no-heading](name)" | \
  xargs --no-run-if-empty gcloud compute firewall-rules delete

gcloud compute http-health-checks list --filter="name ~ ^k8s- AND createTime < $before" --format="table[no-heading](name)" | \
  xargs --no-run-if-empty gcloud compute http-health-checks delete

gcloud compute disks list --filter="name ~ ^gke-$cluster_prefix- AND createTime < $before" --format="table[no-heading](name, zone)" | \
  sed 's/ / --zone /2' | \
  xargs --no-run-if-empty gcloud compute disks delete

gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before" --format="table[no-heading](name, zone)" | \
  sed 's/ / --zone /2' | \
  xargs --no-run-if-empty gcloud compute disks delete