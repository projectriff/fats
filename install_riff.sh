#!/bin/bash

source ./util.sh

go get github.com/projectriff/riff

riff system install
riff namespace init default --secret gcr-creds

# health checks
until kube_ready \
  'pods' \
  'istio-system' \
  'knative=ingressgateway' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'pods' \
  'knative-serving' \
  'app=controller' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'pods' \
  'knative-build' \
  'app=build-controller' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'pods' \
  'knative-eventing' \
  'app=eventing-controller' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'pods' \
  'knative-eventing' \
  'clusterBus=stub' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
