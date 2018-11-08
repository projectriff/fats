#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

minikube stop
minikube delete
