#!/bin/bash

# Install pivnet cli
`dirname "${BASH_SOURCE[0]}"`/../install.sh pivnet

# Install pks cli
pivnet download-product-files -p pivotal-container-service -r 1.4.1 -i 400601 --accept-eula
mv pks-* pks
chmod +x pks
sudo mv pks /usr/local/bin/
