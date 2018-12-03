#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

TS_G_ENV=$(echo $TOOLSMITH_ENV | base64 --decode | jq -r .name)

gcp_region=`gcloud config get-value compute/region`
gcp_zone=`gcloud config get-value compute/zone`

gcloud compute forwarding-rules delete ${TS_G_ENV}-${CLUSTER_NAME}-fw --region=${gcp_region}
gcloud compute target-instances delete ${TS_G_ENV}-${CLUSTER_NAME}-ti --zone=${gcp_zone}
gcloud compute addresses delete ${TS_G_ENV}-${CLUSTER_NAME}-ip --region=${gcp_region}

pks delete-cluster ${TS_G_ENV}-${CLUSTER_NAME} --non-interactive --wait

# delete orphaned resources

set +o errexit
set +o pipefail

cluster_prefix="${TS_G_ENV}-`echo $CLUSTER_NAME | cut -d '-' -f1`"
before=`date -d @$(( $(date +"%s") - 24*3600)) -u +%Y-%m-%dT%H:%M:%SZ` # yesterday

# TODO restore once we can check the creation timestamp
# fats_echo "Cleanup orphaned clusters"
# pks clusters
# pks clusters --json | jq -r '.[].name' | \
#   xargs -L 1 --no-run-if-empty pks delete-cluster --non-interactive --wait
# pks clusters

fats_echo "Cleanup orphaned forwarding rules"
gcloud compute forwarding-rules list --filter="name ~ ^$cluster_prefix- AND createTime < $before"
gcloud compute forwarding-rules list --filter="name ~ ^$cluster_prefix- AND createTime < $before" --format="table[no-heading](name, region)" | \
  sed 's/ / --region /2' | \
  xargs -L 1 --no-run-if-empty gcloud compute forwarding-rules delete
gcloud compute forwarding-rules list --filter="name ~ ^$cluster_prefix- AND createTime < $before"

fats_echo "Cleanup orphaned target instances"
gcloud compute target-instances list --filter="name ~ ^$cluster_prefix- AND createTime < $before"
gcloud compute target-instances list --filter="name ~ ^$cluster_prefix- AND createTime < $before" --format="table[no-heading](name, zone)" | \
  sed 's/ / --zone /2' | \
  xargs -L 1 --no-run-if-empty gcloud compute target-instances delete
gcloud compute target-instances list --filter="name ~ ^$cluster_prefix- AND createTime < $before"

fats_echo "Cleanup orphaned addresses"
gcloud compute addresses list --filter="name ~ ^$cluster_prefix- AND createTime < $before"
gcloud compute addresses list --filter="name ~ ^$cluster_prefix- AND createTime < $before" --format="table[no-heading](name, region)" | \
  sed 's/ / --region /2' | \
  xargs -L 1 --no-run-if-empty gcloud compute addresses delete
gcloud compute addresses list --filter="name ~ ^$cluster_prefix- AND createTime < $before"

fats_echo "Cleanup orphaned disks"
gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before"
gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before" --format="table[no-heading](name, zone)" | \
  sed 's/ / --zone /2' | \
  xargs -L 1 --no-run-if-empty gcloud compute disks delete
gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before"
