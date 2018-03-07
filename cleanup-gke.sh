#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

gcloud container clusters delete $1 --quiet
rm client-secret.json
