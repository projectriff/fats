#!/bin/bash

# Install aws for ECR access
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh aws

# Login for local pushes
$(aws ecr get-login --no-include-email --region us-west-2)

aws sts get-caller-identity

IMAGE_REPOSITORY_PREFIX="$(aws sts get-caller-identity | jq -r .Account).dkr.ecr.us-west-2.amazonaws.com"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --secret push-credentials"

fats_delete_image() {
  local image=$1
  IFS=':' read -r -a image <<< "$1"
  local repo=${image[0]}
  local tag=${image[1]}

  aws ecr batch-delete-image --repository-name $repo --image-ids imageTag=$tag
}

fats_create_push_credentials() {
  local namespace=$1

  local login_cmd=`aws ecr get-login --no-include-email --region us-west-2`
  if ! [[ "$login_cmd" =~ "^docker login -u (\S+) -p (\S+) (\S+)$" ]]; then
    echo "Unexpected output from 'aws ecr get-login'"
    exit 1
  fi
  local username="${BASH_REMATCH[1]}"
  local password="${BASH_REMATCH[2]}"
  local endpoint="${BASH_REMATCH[3]}"

  echo "Create auth secret"
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: push-credentials
  namespace: $(echo -n "$namespace")
  annotations:
    build.knative.dev/docker-0: $(echo -n "$endpoint")
type: kubernetes.io/basic-auth
data:
  username: $(echo -n "$username")
  password: $(echo -n "$password")
EOF
}
