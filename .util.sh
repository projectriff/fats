#!/bin/bash

if [[ "${FATS_LOADED:-x}" == "true" ]]; then
  return
fi
FATS_LOADED=true

source `dirname "${BASH_SOURCE[0]}"`/.travis.sh

ANSI_BLUE="\033[34;1m"

wait_for_service_ip() {
  local name=$1
  local namespace=$2

  wait_kube_ready \
    'service' \
    "$namespace" \
    "$name" \
    '{$.status.loadBalancer.ingress[].ip}' \
    '[0-9]'
}

wait_for_service_hostname() {
  local name=$1
  local namespace=$2
  local pattern=$3

  wait_kube_ready \
    'service' \
    "$namespace" \
    "$name" \
    '{$.status.loadBalancer.ingress[].hostname}' \
    "$pattern"
}

wait_pod_selector_ready() {
  local label=$1
  local namespace=$2

  wait_kube_ready \
    'pods' \
    "$namespace" \
    "$label" \
    '{range .items[*]}{@.metadata.name};{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
    ';Ready=True;'
}

wait_kservice_ready() {
  local name=$1
  local namespace=$2

  wait_knative_ready 'services.serving.knative.dev' "$name" "$namespace"
}

wait_channel_ready() {
  local name=$1
  local namespace=$2

  wait_knative_ready 'channel.eventing.knative.dev' "$name" "$namespace"
}

wait_subscription_ready() {
  local name=$1
  local namespace=$2

  wait_knative_ready 'subscription.eventing.knative.dev' "$name" "$namespace"
}

wait_knative_ready() {
  local type=$1
  local name=$2
  local namespace=$3

  wait_kube_ready \
    "$type" \
    "$namespace" \
    "$name" \
    ';{range @.status.conditions[*]}{@.type}={@.status};{end}' \
    ';Ready=True;'
}

wait_kube_selector_exists() {
  local type=$1
  local selector=$2
  local namespace=$3
  local name=$4

  until kubectl get $type --namespace $namespace -l $selector \
    -o yaml | grep -qE $name; \
    do sleep 1; \
  done
  echo "$type found for $selector in $namespace"
  kubectl get $type --namespace $namespace -l $selector
}

wait_kube_ready() {
  local type=$1
  local namespace=$2
  local jsonpath=$4
  local pattern=$5

  if [[ $3 = *"="* ]]; then
    local selector=$3

    # TODO look for all resources to be ready, not just one
    until kubectl get $type --namespace $namespace -l $selector \
      -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern; \
      do sleep 1; \
    done

  else
    local name=$3

    until kubectl get $type --namespace $namespace $name \
      -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern; \
      do sleep 1; \
    done
  fi
}

fats_echo() {
  echo -e "$ANSI_BLUE[`date -u +%Y-%m-%dT%H:%M:%SZ`]$ANSI_RESET $@"
}
