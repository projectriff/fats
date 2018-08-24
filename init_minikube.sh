#!/bin/bash

export USER_ACCOUNT="${DOCKER_USERNAME}"
export SYSTEM_INSTALL_FLAGS="--node-port"

fats_delete_image() {
  IFS=':' read -r -a image <<< "$1"
  repo=${image[0]}
  tag=${image[1]}

  TOKEN=`curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKER_USERNAME}'", "password": "'${DOCKER_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token`
  curl 'https://hub.docker.com/v2/repositories/${repo}/tags/${tag}/' -X DELETE -H "Authorization: JWT ${TOKEN}"
}
