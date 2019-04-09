#!/bin/bash

aws_iam_version=0.4.0-alpha.1

curl -s -L "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/${aws_iam_version}/aws-iam-authenticator_${aws_iam_version}_linux_amd64" -o aws-iam-authenticator
chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin

unset aws_iam_version
