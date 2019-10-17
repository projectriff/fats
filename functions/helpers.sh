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

delete_stream() {
  local name=$1

  echo "Deleting stream ${name}"
  riff streaming stream delete $name --namespace $NAMESPACE
}

start_portfwd() {
  if [ ! -f `dirname "${BASH_SOURCE[0]}"`/.portfwd ]; then
    touch `dirname "${BASH_SOURCE[0]}"`/.portfwd
    kubectl -n "riff-system" port-forward "svc/riff-streaming-http-gateway" "8080:80" &
    portfwd_pid=$!
    wait_portfwd 8080
  fi
}

post_stream() {
  local name=$1
  local message=$2
  local encoding=${3:-"application/json"}

  start_portfwd

  curl -v http://localhost:8080/${NAMESPACE}/${name} -H "Content-Type: ${encoding}" -d $message
}

create_processor() {
  local name=$1
  local args=$2

  riff streaming processor create $name --function-ref $name --namespace $NAMESPACE $2 --tail
}

start_liiklus_portfwd() {
  if [ ! -f `dirname "${BASH_SOURCE[0]}"`/.liportfwd ]; then
    touch `dirname "${BASH_SOURCE[0]}"`/.liportfwd
    kubectl -n $NAMESPACE port-forward "svc/$(kubectl -n $NAMESPACE get svc -lstreaming.projectriff.io/kafka-provider-liiklus -otemplate --template="{{(index .items 0).metadata.name}}")" "6565:6565" &
    li_portfwd_pid=$!
    wait_portfwd 6565
  fi
}

log_stream() {
  local name=$1
  local leeklusclientversion=0.1.0

  curl -LO https://github.com/projectriff-samples/liiklus-client/releases/download/v${leeklusclientversion}/liiklus-client-${leeklusclientversion}.jar

  start_liiklus_portfwd

  java -jar liiklus-client-0.1.0.jar --consumer localhost:6565 ${NAMESPACE}_${name} > $name.out &
  li_pid=$!
  sleep 10 # wait for the jvm to start
}

cleanup_portfwd() {
  kill $li_pid || true
  kill $portfwd_pid || true
  kill $li_portfwd_pid || true
}