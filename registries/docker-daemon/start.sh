#!/bin/bash

# Enable local registry
echo "Installing a daemon registry"
docker run -d -e REGISTRY_HTTP_ADDR=0.0.0.0:80 -p 80:80 --name registry registry:2

registry_ip=$(docker inspect --format "{{.NetworkSettings.IPAddress }}" registry)
sudo su -c "echo \"${registry_ip} registry.kube-system.svc.cluster.local\" >> /etc/hosts"

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
    targetPort: 80
---
kind: Endpoints
apiVersion: v1
metadata:
  name: registry
  namespace: kube-system
subsets:
  - addresses:
    - ip: ${registry_ip}
    ports:
      - port: 80
EOF
