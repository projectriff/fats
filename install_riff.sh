#!/bin/bash

source ./util.sh

go get github.com/projectriff/riff
riff_home="`go env GOPATH`/src/github.com/projectriff/riff"
riff_version=`cat ${riff_home}/VERSION`

echo "riffVersion: latest" > ~/.riff.yaml

kubectl create namespace riff-system

helm repo add projectriff https://riff-charts.storage.googleapis.com
helm repo update

helm install --name projectriff --namespace riff-system --version $riff_version projectriff/riff --set kafka.create=true

# kafka health checks
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

# riff health checks
until kube_ready \
  'pods' \
  'riff-system' \
  'app=riff,component=function-controller' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'pods' \
  'riff-system' \
  'app=riff,component=topic-controller' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'pods' \
  'riff-system' \
  'app=riff,component=http-gateway' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
until kube_ready \
  'services' \
  'riff-system' \
  'app=riff,component=http-gateway' \
  '{.items[0].status.loadBalancer.ingress[0].ip}' \
  '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' \
; do sleep 1; done
