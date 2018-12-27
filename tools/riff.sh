#!/bin/bash

riff_dir=`mktemp -d riff.XXXX`

curl -L https://storage.googleapis.com/projectriff/riff-cli/releases/latest/riff-linux-amd64.tgz \
  | tar xz -C $riff_dir
chmod +x $riff_dir/riff
sudo mv $riff_dir/riff /usr/local/bin/

rm -rf $riff_dir
