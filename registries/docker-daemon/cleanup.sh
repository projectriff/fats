#!/bin/bash

kubectl delete service registry -n kube-system

docker stop $(docker ps -q --filter ancestor=registry:2 )
