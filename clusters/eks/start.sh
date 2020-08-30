#!/bin/bash

eksctl create cluster --name $CLUSTER_NAME --version 1.16 --verbose 4
