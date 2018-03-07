#!/bin/bash

source ./util.sh

go get github.com/projectriff/riff
riff_home="`go env GOPATH`/src/github.com/projectriff/riff"

echo "riffVersion: `cat ${riff_home}/VERSION`" > ~/.riff.yaml
echo "publishNamespace: riff-system" >> ~/.riff.yaml

kubectl create namespace riff-system

helm install \
  --name transport \
  --namespace riff-system \
  ${riff_home}/helm-charts/kafka

until kube_ready \
  'pods' \
  'riff-system' \
  'app=kafka,component=zookeeper' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
sleep 5
until kube_ready \
  'pods' \
  'riff-system' \
  'app=kafka,component=kafka-broker' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done

helm install \
  --name control \
  --namespace riff-system \
  --values ${riff_home}/helm/values-snapshot.yaml \
  ${riff_home}/helm-charts/riff

until kube_ready \
  'services' \
  'riff-system' \
  'app=riff,component=http-gateway' \
  '{.items[0].status.loadBalancer.ingress[0].ip}' \
  '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' \
; do sleep 1; done
