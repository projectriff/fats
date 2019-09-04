#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/../.helpers.sh

create_function() {
  create_type "function" "$@"
}

invoke_function() {
  local type_name=$1
  local input_data=$2
  local expected_data=$3
  local runtime=$4
  invoke_type "function" $type_name "-H 'Content-Type: text/plain' -d $input_data" $expected_data $runtime
}

destroy_function() {
  destroy_type "function" "$@"
}

run_function() {
  run_type "function" "$@"
}
