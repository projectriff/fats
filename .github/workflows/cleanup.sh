#!/bin/bash

set -o nounset

source ${FATS_DIR}/.util.sh

echo "Uninstall riff system"

source ${FATS_DIR}/macros/cleanup-user-resources.sh





#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source ${FATS_DIR}/.configure.sh

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
