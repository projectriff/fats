#!/bin/bash

if ! [ -x "$(command -v pivnet)" ]; then
  # Install pivnet cli
  curl -Lo pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && \
    chmod +x pivnet && sudo mv pivnet /usr/local/bin/

  pivnet login --api-token=${PIVNET_REFRESH_TOKEN}
fi
