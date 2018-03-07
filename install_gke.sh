#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

go get github.com/GoogleCloudPlatform/docker-credential-gcr

echo $GCLOUD_CLIENT_SECRET | base64 --decode > client-secret.json
gcloud auth activate-service-account --key-file client-secret.json

gcloud config set project cf-spring-pfs-eng
gcloud config set compute/zone us-central1-a

gcloud container clusters create $1
gcloud container clusters get-credentials $1
docker-credential-gcr configure-docker
