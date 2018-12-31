#!/bin/bash

version=0.4.0-alpha.1

curl -s -L "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/${version}/aws-iam-authenticator_${version}_linux_amd64" -o aws-iam-authenticator
chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin
