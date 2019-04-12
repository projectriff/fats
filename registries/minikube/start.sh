#!/bin/bash

# Enable local registry
echo "Installing a local registry"
#!/bin/bash

# Enable local registry
echo "Installing a local registry"
# setup registry
docker run -d -p 5000:5000 registry:2
sudo sed -i 's/127.0.0.1\slocalhost/127.0.0.1     localhost registry.pfs.svc.cluster.local/g' /etc/hosts
# create registry service
dev_ip=172.16.1.1
sudo ifconfig lo:0 $DEV_IP
kubectl create namespace pfs
cat <<EOF | kubectl create -f -
---
kind: Service
apiVersion: v1
metadata:
    name: registry
    namespace: pfs
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
    namespace: pfs
subsets:
    - addresses:
        - ip: $dev_ip
    ports:
        - port: 5000
EOF
