#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/../.helpers.sh

create_function() {
  create_type "function" "$@"
}

invoke_function() {
  local name=$1
  local input_data=$2
  local expected_data=$3
  local runtime=$4
  invoke_type "function" $name "-H Content-Type:text/plain -H Accept:text/plain -d ${input_data}" $expected_data $runtime
}

destroy_function() {
  destroy_type "function" "$@"
}

run_function() {
  run_type "function" "$@"
}

create_stream() {
  local name=$1
  local encoding=$2

  echo "Creating stream ${name}"
  riff streaming stream create $name --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type $encoding
}

post_stream() {
  local name=$1
  local message=$2
  local encoding=${4:-"application/json"}

  curl http://localhost:8080/${NAMESPACE}/${name} -H "Content-Type: ${encoding}" -d $message
}

create_streams() {
  local name=$1
  local args=$2

  riff streaming processor create $name --function-ref $name --namespace $NAMESPACE $2 --tail
}
