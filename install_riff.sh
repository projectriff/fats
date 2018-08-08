#!/bin/bash

source ./util.sh

go get github.com/projectriff/riff

echo "Create auth secret"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: gcr-creds
  annotations:
    build.knative.dev/docker-0: https://us.gcr.io
    build.knative.dev/docker-1: https://gcr.io
    build.knative.dev/docker-2: https://eu.gcr.io
    build.knative.dev/docker-3: https://asia.gcr.io
type: kubernetes.io/basic-auth
data:
  username: $(echo -n "_json_key" | openssl base64 -a -A) # Should be X2pzb25fa2V5
  password: $(echo $GCLOUD_CLIENT_SECRET)
EOF

riff system install
riff namespace init default --secret gcr-creds

# health checks
echo "Checking for ready pods"
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
