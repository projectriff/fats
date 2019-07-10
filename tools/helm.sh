#!/bin/bash

helm_version="${1:-2.14.1}"
base_url="${2:-https://get.helm.sh}"

if [ "$machine" == "MinGw" ]; then

  curl -L ${base_url}/helm-v${helm_version}-windows-amd64.zip > helm.zip
  unzip helm.zip -d /usr/bin/
  rm helm.zip
else
  helm_dir=`mktemp -d helm.XXXX`

  curl -L ${base_url}/helm-v${helm_version}-linux-amd64.tar.gz | tar xz -C $helm_dir --strip-components 1
  chmod +x $helm_dir/helm
  sudo mv $helm_dir/helm /usr/local/bin/

  rm -rf $helm_dir

  sudo apt-get install socat
fi
