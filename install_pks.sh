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

gcp_region=`gcloud config get-value compute/region`
gcp_zone=`gcloud config get-value compute/zone`
gcloud compute addresses create ${TS_G_ENV}-${CLUSTER_NAME}-ip --region=${gcp_region}
lb_ip=`gcloud compute addresses list --filter="name=(${TS_G_ENV}-${CLUSTER_NAME}-ip)" --format=json | jq -r .[0].address`

travis_wait 60 pks create-cluster ${TS_G_ENV}-${CLUSTER_NAME} --external-hostname ${lb_ip} --plan large --wait

master_ip=`pks cluster ${TS_G_ENV}-${CLUSTER_NAME} --json | jq -r .kubernetes_master_ips[0]`
master_name=`gcloud compute instances list --format=json | jq -r ".[] | select(.networkInterfaces[].networkIP == \"${master_ip}\") | .name"`
gcloud compute target-instances create ${TS_G_ENV}-${CLUSTER_NAME}-ti --instance ${master_name} --zone=${gcp_zone}
gcloud compute forwarding-rules create ${TS_G_ENV}-${CLUSTER_NAME}-fw --target-instance=${TS_G_ENV}-${CLUSTER_NAME}-ti --address=${lb_ip} \
 --region=${gcp_region} --target-instance-zone=${gcp_zone}

 pks get-credentials ${TS_G_ENV}-${CLUSTER_NAME}
