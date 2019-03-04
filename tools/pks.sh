#!/bin/bash

# Install pivnet cli
`dirname "${BASH_SOURCE[0]}"`/../install.sh pivnet

# Install pks cli
pivnet download-product-files -p pivotal-container-service -r 1.2.3 -i 268848 --accept-eula
mv pks-* pks
chmod +x pks
sudo mv pks /usr/local/bin/
