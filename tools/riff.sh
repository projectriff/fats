#!/bin/bash

riff_version="latest"

if [ "$machine" == "MinGw" ]; then
  curl -L https://storage.googleapis.com/projectriff/riff-cli/releases/${riff_version}/riff-windows-amd64.zip > riff.zip
  unzip riff.zip /usr/bin/
  rm riff.zip
else
  riff_dir=`mktemp -d riff.XXXX`

  curl -L https://storage.googleapis.com/projectriff/riff-cli/releases/${riff_version}/riff-linux-amd64.tgz \
    | tar xz -C $riff_dir
  chmod +x $riff_dir/riff
  sudo mv $riff_dir/riff /usr/local/bin/

  rm -rf $riff_dir
fi
