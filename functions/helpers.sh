#!/bin/bash

create_function() {
  local path=$1
  local function_name=$2
  local image=$3
  local args=$4
  local runtime=${5:-core}

  echo "Create function $function_name"

  pushd $path
    if [ -e '.fats/create' ]; then
      args="${args} `cat .fats/create`"
    fi

    # create function
    fats_echo "Creating $function_name:"
    riff function create $function_name $args --image $image --namespace $NAMESPACE --tail &
    riff $runtime deployer create $function_name --function-ref $function_name --namespace $NAMESPACE --tail

    # TODO reduce/eliminate this sleep
    sleep 5
  popd
}

invoke_function() {
  local function_name=$1
  local input_data=$2
  local expected_data=$3
  local runtime=${4:-core}

  echo "Invoke function $function_name"

  if [ $runtime = "core" ]; then
    svc=$(kubectl get deployers.core.projectriff.io --namespace $NAMESPACE ${function_name} -o jsonpath='{$.status.serviceName}')
    kubectl port-forward --namespace $NAMESPACE service/${svc} 8080:80 &
    pf_pid=$!

    # wait for the port-forward to be ready
    if [ -x "$(command -v nc)" ]; then
      while ! nc -z localhost 8080; do
        sleep 1
      done
      sleep 2
    else
      sleep 5
    fi

    curl localhost:8080 \
      -H "Content-Type: text/plain" \
      -d $input_data \
      -v | tee $function_name.out

    kill $pf_pid
  elif [ $runtime = "knative" ]; then
    ip=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.status.loadBalancer.ingress[0].ip}')
    port="80"
    if [ -z "$ip" ]; then
      ip="localhost"
      port=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.spec.ports[?(@.name=="http2")].nodePort}')
    fi
    hostname=$(kubectl get deployers.knative.projectriff.io --namespace $NAMESPACE ${function_name} -o jsonpath='{$.status.url}' | sed -e 's|http://||g')

    curl ${ip}:${port} \
      -H "Host: ${hostname}" \
      -H "Content-Type: text/plain" \
      -d $input_data \
      -v | tee $function_name.out
  fi

  # add a new line after invoke, but without impacting the curl output
  echo ""
}

destroy_function() {
  local function_name=$1
  local image=$2
  local runtime=${3:-core}

  echo "Destroy function $function_name"

  riff $runtime deployer delete $function_name --namespace $NAMESPACE
  riff function delete $function_name --namespace $NAMESPACE
  fats_delete_image $image
}

run_function() {
  local path=$1
  local function_name=$2
  local image=$3
  local create_args=$4
  local input_data=$5
  local expected_data=$6
  local runtime=${7:-core}

  echo "Run function $function_name"

  echo -e "${ANSI_BLUE}> path:${ANSI_RESET} ${path}"
  echo -e "${ANSI_BLUE}> name:${ANSI_RESET} ${function_name}"
  echo -e "${ANSI_BLUE}> image:${ANSI_RESET} ${image}"
  echo -e "${ANSI_BLUE}> args:${ANSI_RESET} ${create_args}"
  echo -e "${ANSI_BLUE}> runtime:${ANSI_RESET} ${runtime}"

  create_function $path $function_name $image "$create_args" $runtime
  invoke_function $function_name $input_data $expected_data $runtime
  destroy_function $function_name $image $runtime

  local actual_data=`cat $function_name.out | tail -1`
  if [ "$actual_data" != "$expected_data" ]; then
    echo -e "${ANSI_RED}Function did not produce expected result${ANSI_RESET}:";
    echo -e "   expected: $expected_data"
    echo -e "   actual: $actual_data"
    exit 1
  fi
}
