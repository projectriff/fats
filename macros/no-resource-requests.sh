#!/bin/bash

if [ $(kubectl get nodes -oname | wc -l) = "1" ]; then
  echo "Eliminate pod resource requests"
  fats_retry kubectl apply -f https://storage.googleapis.com/projectriff/no-resource-requests-webhook/no-resource-requests-webhook-20200228131048-cfc48caa7c456cbb.yaml
  wait_pod_selector_ready app=webhook no-resource-requests
fi
