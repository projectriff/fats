#!/bin/bash

kind_version="${1:-v0.5.1}"
base_url="${2:-https://github.com/kubernetes-sigs/kind/releases/download}"
curl_retries=3

if [ "$machine" == "MinGw" ]; then
  curl -Lo kind.exe ${base_url}/${kind_version}/kind-windows-amd64 --retry ${curl_retries}
  mv kind.exe /usr/bin/
else
  curl -Lo kind ${base_url}/${kind_version}/kind-linux-amd64 --retry ${curl_retries}
  chmod +x kind
  sudo mv kind /usr/local/bin/
fi
