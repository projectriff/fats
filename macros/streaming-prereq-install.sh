#!/bin/bash

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --name my-kafka bitnami/kafka

cat <<EOF | kubectl create -f -
---
apiVersion: streaming.projectriff.io/v1alpha1
kind: KafkaProvider
metadata:
  name: franz
spec:
  bootstrapServers: my-kafka:9092
EOF

kubectl apply -f https://storage.googleapis.com/projectriff/riff-http-gateway/riff-http-gateway-0.5.0-snapshot.yaml
