#!/bin/bash		
		
set -o errexit		
set -o nounset		
set -o pipefail		
		
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/${1}/bin/linux/amd64/kubectl		
chmod +x kubectl		
sudo mv kubectl /usr/local/bin/
