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

cluster_prefix=${1:-fats}
before=`date -d @$(( $(date +"%s") - 24*3600)) -u +%Y-%m-%dT%H:%M:%SZ` # yesterday

gcloud config unset compute/region
gcloud config unset compute/zone

fats_echo "Cleanup orphaned disks"
gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before"
gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before" --format="table[no-heading](name, zone)" | \
  sed 's/ / --zone /2' | \
  xargs -L 1 --no-run-if-empty gcloud compute disks delete
gcloud compute disks list --filter="name ~ ^disk- AND createTime < $before"
