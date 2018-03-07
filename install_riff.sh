#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

curl -L https://github.com/projectriff/riff/tarball/${1} | tar xz
mv projectriff-* projectriff
export RIFF_VERSION=`cat projectriff/VERSION`

go get github.com/projectriff/riff

kubectl create namespace riff-system
helm install --name transport --namespace riff-system ./projectriff/helm-charts/kafka
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get pods --namespace riff-system -l release=transport,app=kafka,component=zookeeper -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
sleep 5
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get pods --namespace riff-system -l release=transport,app=kafka,component=kafka-broker -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done

helm install --name control \
  --set functionController.image.tag=$RIFF_VERSION \
  --set functionController.sidecar.image.tag=$RIFF_VERSION \
  --set topicController.image.tag=$RIFF_VERSION \
  --set httpGateway.image.tag=$RIFF_VERSION \
  ./projectriff/helm-charts/riff
JSONPATH='{.status.loadBalancer.ingress[0].ip}'; \
  until kubectl get svc --namespace default control-riff-http-gateway -o jsonpath="$JSONPATH" 2>&1 | grep -q -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"; do sleep 1; done
