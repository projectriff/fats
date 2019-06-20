#!/bin/bash

duffle_version="${1:-0.1.0-ralpha.5%2Benglishrose}"
base_url="${2:-https://github.com/deislabs/duffle/releases/download}"

if [ "$machine" == "MinGw" ]; then
  curl -L ${base_url}/${duffle_version}/duffle-windows-amd64.exe > duffle.exe
  mv duffle /usr/bin/
else
  curl -L ${base_url}/${duffle_version}/duffle-linux-amd64 > duffle
  chmod +x duffle
  sudo mv duffle /usr/local/bin/
fi
