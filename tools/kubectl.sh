#!/bin/bash

curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.12.3/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
