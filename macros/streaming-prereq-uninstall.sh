#!/bin/bash

helm delete --purge my-kafka

riff streaming kafka-provider delete franz

kubectl delete -f https://storage.googleapis.com/projectriff/riff-http-gateway/riff-http-gateway-0.5.0-snapshot.yaml
