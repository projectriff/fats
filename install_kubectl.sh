#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

mkdir -p kail
curl -L https://github.com/boz/kail/releases/download/v0.6.0/kail_0.6.0_linux_amd64.tar.gz \
  | tar xz -C kail
chmod +x kail/kail
sudo mv kail/kail /usr/local/bin/
