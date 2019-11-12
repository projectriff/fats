#!/bin/bash

CLUSTER_NAME=${CLUSTER_NAME-fats}
kind delete cluster --name ${CLUSTER_NAME}
