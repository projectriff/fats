#!/bin/bash

d=`mktemp -d riff.XXXX`

pushd $d
  echo 'module temp' > go.mod
  GO111MODULE=on go get github.com/projectriff/riff@master
popd

rm -r "$d"
