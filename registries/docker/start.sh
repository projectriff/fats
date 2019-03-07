#!/bin/bash

# Enable local registry
echo "Installing a local registry"
docker run --detach --publish 80:5000 --rm --name registry registry:2
