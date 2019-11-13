#!/bin/bash

# Enable local registry
echo "Installing a daemon registry"
docker run -d -p 5000:5000 --name registry registry:2

registry_ip=$(docker inspect --format "{{.NetworkSettings.IPAddress }}" registry)
if ! grep registry /etc/hosts; then
  # Still a bug here if the address changes
  sudo su -c "echo \"${registry_ip} registry.kube-system.svc.cluster.local\" >> /etc/hosts"
fi

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
    port: 5000
    targetPort: 5000
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
      - port: 5000
EOF
