#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

RED='\033[0;31m'
BLUE='\e[104m'
NC='\033[0m' # No Color

pod_query_ready() {
  label=$1
  namespace=$2

  kube_ready \
    'pods' \
    "$nameapce" \
    "$label" \
    '{range .items[*]}{@.metadata.name};{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
    ';Ready=True;'
}

kservice_ready() {
  name=$1
  namespace=$2

  knative_ready 'services.serving.knative.dev' "$name" "$namespace"
}

channel_ready() {
  name=$1
  namespace=$2

  knative_ready 'channel.channels.knative.dev' "$name" "$namespace"
}

subscription_ready() {
  name=$1
  namespace=$2

  knative_ready 'subscription.channels.knative.dev' "$name" "$namespace"
}

knative_ready() {
  type=$1
  name=$2
  namespace=$3

  kube_ready \
    "$type" \
    "$namespace" \
    "$name" \
    ';{range @.status.conditions[*]}{@.type}={@.status};{end}' \
    ';Ready=True;'
}

kube_ready() {
  type=$1
  namespace=$2
  jsonpath=$4
  pattern=$5

  if [[ $3 = *"="* ]]; then
    label=$3

    # TODO look for all resources to be ready, not just one
    kubectl get $type --namespace $namespace -l $label \
      -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern
  else
    name=$3

    kubectl get $type --namespace $namespace $name \
      -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern
  fi
}

fats_echo() {
  echo -e "$BLUE[`date -u +%Y-%m-%dT%H:%M:%SZ`]$NC $@"
}
