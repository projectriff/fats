#!/bin/bash

pivnet_version="${1:-0.0.55}"

# Install pivnet cli
curl -Lo pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v${pivnet_version}/pivnet-linux-amd64-${pivnet_version} && \
  chmod +x pivnet && sudo mv pivnet /usr/local/bin/

pivnet login --api-token=${PIVNET_REFRESH_TOKEN}
