#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`

source $dir/util.sh

minikube stop
minikube delete
