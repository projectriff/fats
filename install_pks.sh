#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`

source $dir/util.sh

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

# TODO uncomment if we use a PKS cluster per job
# pks create-cluster ${TS_G_ENV}-${CLUSTER_NAME} --external-hostname ${CLUSTER_NAME}.${TS_G_ENV}.cf-app.com --plan small --wait
# TODO setup loadbalancer, see https://docs.pivotal.io/runtimes/pks/1-2/gcp-cluster-load-balancer.html

# TODO uncomment if usering a PKS cluster per jobs
# pks get-credentials ${TS_G_ENV}-${CLUSTER_NAME}
pks get-credentials ${TS_G_ENV}-fats
