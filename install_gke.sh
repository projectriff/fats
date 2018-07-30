#!/bin/bash

source ./util.sh

go get github.com/GoogleCloudPlatform/docker-credential-gcr

# Create environment variable for correct distribution
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"

# Add the Cloud SDK distribution URI as a package source
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud Platform public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Update the package list and install the Cloud SDK
sudo apt-get update && sudo apt-get install google-cloud-sdk

gcloud config set project cf-spring-pfs-eng
gcloud config set compute/zone us-central1-a
gcloud config set disable_prompts True

echo $GCLOUD_CLIENT_SECRET | base64 --decode > client-secret.json
gcloud auth activate-service-account --key-file client-secret.json
rm client-secret.json

gcloud container clusters create --num-nodes 2 $CLUSTER_NAME
gcloud container clusters get-credentials $CLUSTER_NAME
docker-credential-gcr configure-docker

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value core/account)
