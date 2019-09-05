#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/../.helpers.sh

create_application() {
  create_type "application" "$@"
}

invoke_application() {
  local type_name=$1
  local input_data=$2
  local expected_data=$3
  local runtime=$4
  invoke_type "application" $type_name "--get --data-urlencode input=$input_data"  $expected_data $runtime
}

destroy_application() {
  destroy_type "application" "$@"
}

run_application() {
  run_type "application" "$@"
}
