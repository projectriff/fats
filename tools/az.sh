#!/bin/bash

# from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest

sudo apt-get install apt-transport-https lsb-release software-properties-common -y
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" \
  | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
  --keyserver packages.microsoft.com \
  --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF

sudo apt-get update
sudo apt-get install azure-cli

# login
az login --service-principal \
  -u $(echo $AZURE_ENV | base64 --decode | jq -r .name) \
  -p $(echo $AZURE_ENV | base64 --decode | jq -r .password) \
  --tenant $(echo $AZURE_ENV | base64 --decode | jq -r .tenant)
