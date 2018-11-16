#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

# Install pivnet cli
curl -Lo pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && \
  chmod +x pivnet && sudo mv pivnet /usr/local/bin/

# Install pks cli
pivnet login --api-token=${PIVNET_REFRESH_TOKEN}
pivnet download-product-files -p pivotal-container-service -r 1.2.0 -i 219539 --accept-eula
mv pks-* pks
chmod +x pks
sudo mv pks /usr/local/bin/

# Install and configure gcloud for GCR access
fats_setup_gcloud

# Create pks cluster
export TS_G_ENV=$(echo $TOOLSMITH_ENV | base64 --decode | jq -r .name)
export UAA_ADMIN_PASSWORD=$(echo $TOOLSMITH_ENV | base64 --decode | jq -r .pks_api.uaa_admin_password)

pks login -a api.pks.${TS_G_ENV}.cf-app.com -u admin -p ${UAA_ADMIN_PASSWORD} -k

gcloud compute addresses create ${TS_G_ENV}-${CLUSTER_NAME}-ip --region=${CLOUDSDK_COMPUTE_REGION}
export LB_IP=`gcloud compute addresses list --filter="name=(${TS_G_ENV}-${CLUSTER_NAME}-ip)" --format=json | jq -r .[0].address`

pks create-cluster ${TS_G_ENV}-${CLUSTER_NAME} --external-hostname ${LB_IP} --plan large --wait
# TODO setup loadbalancer, see https://docs.pivotal.io/runtimes/pks/1-2/gcp-cluster-load-balancer.html
export MASTER_IP=`pks cluster ${TS_G_ENV}-${CLUSTER_NAME} --json | jq -r .kubernetes_master_ips[0]`
export MASTER_NAME=`gcloud compute instances list --format=json | jq -r ".[] | select(.networkInterfaces[].networkIP == \"${MASTER_IP}\") | .name"`

gcloud compute target-instances create ${TS_G_ENV}-${CLUSTER_NAME}-ti --instance ${MASTER_NAME} --zone=${CLOUDSDK_COMPUTE_ZONE}
gcloud compute forwarding-rules create ${TS_G_ENV}-${CLUSTER_NAME}-fw --target-instance=${TS_G_ENV}-${CLUSTER_NAME}-ti --address=${LB_IP} \
 --region=${CLOUDSDK_COMPUTE_REGION} --target-instance-zone=${CLOUDSDK_COMPUTE_ZONE}

pks get-credentials ${TS_G_ENV}-${CLUSTER_NAME}
