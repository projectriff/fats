#!/bin/bash

kubectl delete service registry -n kube-system
kubectl delete endpoint registry -n kube-system

docker stop registry
docker rm registry
