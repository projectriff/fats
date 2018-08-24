#!/bin/bash

source ./util.sh

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

gcloud container clusters create $CLUSTER_NAME \
  --cluster-version=latest \
  --machine-type=n1-standard-4 \
  --enable-autoscaling --min-nodes=1 --max-nodes=3 \
  --enable-autorepair \
  --scopes=service-control,service-management,compute-rw,storage-ro,cloud-platform,logging-write,monitoring-write,pubsub,datastore \
  --num-nodes=3

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value core/account)

echo "Create auth secret"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: push-credentials
  annotations:
    build.knative.dev/docker-0: https://us.gcr.io
    build.knative.dev/docker-1: https://gcr.io
    build.knative.dev/docker-2: https://eu.gcr.io
    build.knative.dev/docker-3: https://asia.gcr.io
type: kubernetes.io/basic-auth
data:
  username: $(echo -n "_json_key" | openssl base64 -a -A) # Should be X2pzb25fa2V5
  password: $(echo $GCLOUD_CLIENT_SECRET)
EOF
