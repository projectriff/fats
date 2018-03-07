#!/bin/bash

source ./util.sh

curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.2/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
