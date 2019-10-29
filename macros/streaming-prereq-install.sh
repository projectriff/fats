#!/bin/bash

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --name my-kafka bitnami/kafka

riff streaming kafka-provider create franz --bootstrap-servers my-kafka:9092

kubectl apply -f https://storage.googleapis.com/projectriff/riff-http-gateway/riff-http-gateway-0.5.0-snapshot.yaml

kubectl -n "riff-system" port-forward "svc/riff-streaming-http-gateway" "8080:80" &	
pf_pid=$!
