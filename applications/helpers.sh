#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/../.testhelpers.sh

create_application() {
  create_type "application" "$@"
}

invoke_application() {
  invoke_type "application" "$@"
}

destroy_application() {
  destroy_type "application" "$@"
}

run_application() {
  run_type "application" "$@"
}
