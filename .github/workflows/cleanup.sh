#!/bin/bash

set -o nounset

source ${FATS_DIR}/.util.sh

echo "Uninstall riff system"

source ${FATS_DIR}/macros/cleanup-user-resources.sh





#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

readonly riff_version=0.5.0-snapshot

source ${FATS_DIR}/.configure.sh

export KO_DOCKER_REPO=$(fats_image_repo '#' | cut -d '#' -f 1 | sed 's|/$||g')
kubectl create ns apps

echo "Removing Kafka"
kapp delete -n apps -a kafka -y

echo "Removing riff Streaming Runtime"
kapp delete -n apps -a riff-streaming-runtime -y

echo "Removing KEDA"
kapp delete -n apps -a keda -y

echo "Removing riff Knative Runtime"
kapp delete -n apps -a riff-knative-runtime -y

echo "Removing Knative Serving"
kapp delete -n apps -a knative -y

echo "Removing Istio"
kapp delete -n apps -a istio -y

echo "Removing riff Core Runtime"
kapp delete -n apps -a riff-core-runtime -y

echo "Removing riff Build"
kapp delete -n apps -a riff-build -y
kapp delete -n apps -a riff-builders -y

echo "Removing kpack"
kapp delete -n apps -a kpack -y

echo "Removing Cert Manager"
kapp delete -n apps -a cert-manager -y

kubectl delete namespace ${NAMESPACE}
