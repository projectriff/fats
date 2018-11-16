#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

fats_setup_gcloud

export TS_G_ENV=$(echo $TOOLSMITH_ENV | base64 --decode | jq -r .name)
gcloud compute forwarding-rules delete ${TS_G_ENV}-${CLUSTER_NAME}-fw --region=${CLOUDSDK_COMPUTE_REGION}
gcloud compute target-instances delete ${TS_G_ENV}-${CLUSTER_NAME}-ti --zone=${CLOUDSDK_COMPUTE_ZONE}
gcloud compute addresses delete ${TS_G_ENV}-${CLUSTER_NAME}-ip --region=${CLOUDSDK_COMPUTE_REGION}

pks delete-cluster ${TS_G_ENV}-${CLUSTER_NAME} --non-interactive --wait

