#!/bin/bash

if [ "$machine" == "MinGw" ]; then
  # binaries are not available for windows, we need to build from source
  # export GOPATH=$(go env GOPATH)
  # go get -d github.com/boz/kail
  # pushd $GOPATH/src/github.com/boz/kail
  #   git checkout v0.7.0
  #   make install-deps
  #   make
  #   mv kail.exe /usr/bin/
  # popd

  # stub out kail for now
  cat <<EOF > /usr/bin/kail
#!/bin/bash

echo "kail output is not supported on this platform"
sleep 600
EOF
else
  mkdir -p kail
  curl -L https://github.com/boz/kail/releases/download/v0.7.0/kail_0.7.0_linux_amd64.tar.gz \
    | tar xz -C kail
  chmod +x kail/kail
  sudo mv kail/kail /usr/local/bin/
fi
