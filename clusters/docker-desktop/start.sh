#!/bin/bash

# Wait for Kubernetes to be up and ready.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done

wait_pod_selector_ready component=kube-apiserver kube-system
wait_pod_selector_ready component=kube-scheduler kube-system
wait_pod_selector_ready component=etcd kube-system
