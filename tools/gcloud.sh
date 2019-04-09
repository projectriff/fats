#!/bin/bash

gcloud_version=241.0.0

if hash choco 2>/dev/null; then
  gcloud_dir="/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk"
  curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_version}-windows-x86.zip > gcloud.zip
  mkdir -p "${gcloud_dir}"
  unzip gcloud.zip -d "${gcloud_dir}"
  rm gcloud.zip
else
  gcloud_dir="$HOME/google-cloud-sdk"
  curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_version}-linux-x86_64.tar.gz  \
    | tar xz -C $gcloud_dir
fi

echo "##vso[task.prependpath]${gcloud_dir}/bin"
export PATH="${gcloud_dir}/bin:$PATH"

gcloud config set project cf-spring-pfs-eng
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud config set disable_prompts True

echo $GCLOUD_CLIENT_SECRET | base64 --decode > key.json
gcloud auth activate-service-account --key-file key.json
rm key.json
gcloud auth configure-docker
