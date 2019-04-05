#!/bin/bash

if [ "$machine" == "MinGw" ]; then
  # binaries are not available for windows, we need to build from source
  go get github.com/boz/kail/cmd/kail
else
  mkdir -p kail
  curl -L https://github.com/boz/kail/releases/download/v0.7.0/kail_0.7.0_linux_amd64.tar.gz \
    | tar xz -C kail
  chmod +x kail/kail
  sudo mv kail/kail /usr/local/bin/
fi
