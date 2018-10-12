#!/bin/bash

set -x

if [[ "$OS_NAME" == "windows" ]]; then
  sudo() {
    $@
  }
fi

set -o errexit
set -o nounset
set -o pipefail

RED='\033[0;31m'
BLUE='\e[104m'
NC='\033[0m' # No Color

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
