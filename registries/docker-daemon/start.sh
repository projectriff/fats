#!/bin/bash

# Enable local registry
echo "Installing a local registry"
docker run -d -p 5000:5000 registry:2

dev_ip=172.16.1.1
sudo su -c "echo \"\" >> /etc/hosts"
sudo su -c "echo \"$dev_ip       registry.kube-system.svc.cluster.local\" >> /etc/hosts"
sudo ifconfig lo:0 $dev_ip
cat <<EOF | kubectl create -f -
---
kind: Service
apiVersion: v1
metadata:
  name: registry
  namespace: kube-system
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5000
---
kind: Endpoints
apiVersion: v1
metadata:
  name: registry
  namespace: kube-system
subsets:
  - addresses:
    - ip: $dev_ip
    ports:
      - port: 5000
EOF
