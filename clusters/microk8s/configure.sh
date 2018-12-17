#!/bin/bash

wait_for_ingress_ready() {
  name=$1
  namespace=$2

  # nothing to do
}

# allow network access from inside pods
sudo iptables -P FORWARD ACCEPT
