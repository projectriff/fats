#!/bin/bash

travis_wait 40 eksctl create cluster --name $CLUSTER_NAME
