#!/bin/bash

if [[ "${FATS_CONFIGURED:-x}" == "x" ]]; then
  echo -e "Configuring FATS run:"
  echo -e "    cluster ${ANSI_BLUE}${CLUSTER}${ANSI_RESET}"
  echo -e "    registry ${ANSI_BLUE}${REGISTRY}${ANSI_RESET}"

  source `dirname "${BASH_SOURCE[0]}"`/clusters/${CLUSTER}/configure.sh
  source `dirname "${BASH_SOURCE[0]}"`/registries/${REGISTRY}/configure.sh

  FATS_CONFIGURED=true
fi
