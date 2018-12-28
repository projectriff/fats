#!/bin/bash

travis_wait eksctl create cluster --name $CLUSTER_NAME
