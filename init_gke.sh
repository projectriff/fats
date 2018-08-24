#!/bin/bash

export USER_ACCOUNT="gcr.io/`gcloud config get-value project`"
export SYSTEM_INSTALL_FLAGS=""

fats_delete_image() {
  image=$1

  gcloud container images delete $image
}
