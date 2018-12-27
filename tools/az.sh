#!/bin/bash

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" \
  | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

# login
az login --service-principal \
  -u $(echo $AZURE_ENV | base64 --decode | jq -r .name) \
  -p $(echo $AZURE_ENV | base64 --decode | jq -r .password) \
  --tenant $(echo $AZURE_ENV | base64 --decode | jq -r .tenant)
