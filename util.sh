#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

RED='\033[0;31m'
BLUE='\e[104m'
NC='\033[0m' # No Color

wait_for_service_ip() {
  name=$1
  namespace=$2

  wait_kube_ready \
    'service' \
    "$namespace" \
    "$name" \
    '{$.status.loadBalancer.ingress[].ip}' \
    '[0-9]'
}

wait_pod_selector_ready() {
  label=$1
  namespace=$2

  wait_kube_ready \
    'pods' \
    "$namespace" \
    "$label" \
    '{range .items[*]}{@.metadata.name};{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
    ';Ready=True;'
}

wait_kservice_ready() {
  name=$1
  namespace=$2

  wait_knative_ready 'services.serving.knative.dev' "$name" "$namespace"
}

wait_channel_ready() {
  name=$1
  namespace=$2

  wait_knative_ready 'channel.channels.knative.dev' "$name" "$namespace"
}

wait_subscription_ready() {
  name=$1
  namespace=$2

  wait_knative_ready 'subscription.channels.knative.dev' "$name" "$namespace"
}

wait_knative_ready() {
  type=$1
  name=$2
  namespace=$3

  wait_kube_ready \
    "$type" \
    "$namespace" \
    "$name" \
    ';{range @.status.conditions[*]}{@.type}={@.status};{end}' \
    ';Ready=True;'
}

wait_kube_selector_exists() {
  type=$1
  selector=$2
  namespace=$3
  name=$4

  until kubectl get $type --namespace $namespace -l $selector \
    -o yaml | grep -qE $name; \
    do sleep 1; \
  done
  echo "$type found for $selector in $namespace"
  kubectl get $type --namespace $namespace -l $selector
}

wait_kube_ready() {
  type=$1
  namespace=$2
  jsonpath=$4
  pattern=$5

  if [[ $3 = *"="* ]]; then
    selector=$3

    # TODO look for all resources to be ready, not just one
    until kubectl get $type --namespace $namespace -l $selector \
      -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern; \
      do sleep 1; \
    done

  else
    name=$3

    until kubectl get $type --namespace $namespace $name \
      -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern; \
      do sleep 1; \
    done
  fi
}

fats_echo() {
  echo -e "$BLUE[`date -u +%Y-%m-%dT%H:%M:%SZ`]$NC $@"
}

fats_setup_gcloud() {
  # Create environment variable for correct distribution
  export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"

  # Add the Cloud SDK distribution URI as a package source
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

  # Import the Google Cloud Platform public key
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

  # Update the package list and install the Cloud SDK
  sudo apt-get update && sudo apt-get install google-cloud-sdk

  gcloud config set project cf-spring-pfs-eng
  gcloud config set compute/region us-central1
  gcloud config set compute/zone us-central1-a
  # TODO debug why config set for region and zone does not work
  # current workaround is to use the env variables below
  export CLOUDSDK_COMPUTE_REGION="us-central1"
  export CLOUDSDK_COMPUTE_ZONE="us-central1-a"
  gcloud config set disable_prompts True

  echo $GCLOUD_CLIENT_SECRET | base64 --decode > client-secret.json
  gcloud auth activate-service-account --key-file client-secret.json
  rm client-secret.json

  gcloud auth configure-docker
}
