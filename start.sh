#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/.util.sh

source `dirname "${BASH_SOURCE[0]}"`/.configure.sh

source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/start.sh
source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/start.sh
