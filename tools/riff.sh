#!/bin/bash

riff_dir=`mktemp -d riff.XXXX`

curl -L https://github.com/projectriff/riff/releases/download/v0.2.0/riff-linux-amd64.tgz \
  | tar xz -C $riff_dir
chmod +x $riff_dir/riff
sudo mv $riff_dir/riff /usr/local/bin/

rm -rf $riff_dir
