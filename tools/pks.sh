#!/bin/bash

# Install pivnet cli
`dirname "${BASH_SOURCE[0]}"`/../install.sh pivnet

# Install pks cli
pivnet download-product-files --product-slug='pivotal-container-service' --release-version='1.5.1' --product-file-id=496006 --accept-eula
mv pks-* pks
chmod +x pks
sudo mv pks /usr/local/bin/
