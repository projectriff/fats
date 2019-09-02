#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/../.testhelpers.sh

create_function() {
  create_type "function" "$@"
}

invoke_function() {
  invoke_type "function" "Content-Type: text/plain" "$@"
}

destroy_function() {
  destroy_type "function" "$@"
}

run_function() {
  run_type "function" "$@"
}
