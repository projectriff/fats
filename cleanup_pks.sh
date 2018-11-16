#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

TS_G_ENV=$(echo $TOOLSMITH_ENV | base64 --decode | jq -r .name)

gcp_region=`gcloud config get-value compute/region`
gcp_zone=`gcloud config get-value compute/zone`

gcloud compute forwarding-rules delete ${TS_G_ENV}-${CLUSTER_NAME}-fw --region=${gcp_region}
gcloud compute target-instances delete ${TS_G_ENV}-${CLUSTER_NAME}-ti --zone=${gcp_zone}
gcloud compute addresses delete ${TS_G_ENV}-${CLUSTER_NAME}-ip --region=${gcp_region}
travis_wait 60 pks delete-cluster ${TS_G_ENV}-${CLUSTER_NAME} --non-interactive --wait
