#!/bin/bash

source ./util.sh

go get github.com/GoogleCloudPlatform/docker-credential-gcr

echo $GCLOUD_CLIENT_SECRET | base64 --decode > client-secret.json
gcloud auth activate-service-account --key-file client-secret.json
rm client-secret.json

gcloud config set project cf-spring-pfs-eng
gcloud config set compute/zone us-central1-a
gcloud config set disable_prompts True

gcloud container clusters create $CLUSTER_NAME
gcloud container clusters get-credentials $CLUSTER_NAME
docker-credential-gcr configure-docker
