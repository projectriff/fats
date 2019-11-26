#!/bin/bash

# install kafka for streaming
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm install --name kafka incubator/kafka --set replicas=1,zookeeper.replicaCount=1,zookeeper.env.ZK_HEAP_SIZE=128m --namespace kafka --wait
