#!/bin/bash

create_type() {
  local type=$1
  local path=$2
  local type_name=$3
  local image=$4
  local args=$5
  local runtime=${6:-core}

  echo "Create $type $type_name"

  pushd $path
    if [ -e '.fats/create' ]; then
      args="${args} `cat .fats/create`"
    fi

    # create function/application
    fats_echo "Creating $type_name:"
    riff $type create $type_name $args --image $image --namespace $NAMESPACE --tail &
    riff $runtime deployer create $type_name --$type-ref $type_name --namespace $NAMESPACE --tail

    # TODO reduce/eliminate this sleep
    sleep 5
  popd
}

invoke_type() {
  local type=$1
  local header=$2
  local type_name=$3
  local input_data=$4
  local expected_data=$5
  local runtime=${6:-core}

  echo "Invoke $type $type_name"

  if [ $runtime = "core" ]; then
    svc=$(kubectl get deployers.core.projectriff.io --namespace $NAMESPACE ${type_name} -o jsonpath='{$.status.serviceName}')
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
      -H "$header" \
      -d $input_data \
      -v | tee $type_name.out

    kill $pf_pid
  elif [ $runtime = "knative" ]; then
    ip=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.status.loadBalancer.ingress[0].ip}')
    port="80"
    if [ -z "$ip" ]; then
      ip="localhost"
      port=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.spec.ports[?(@.name=="http2")].nodePort}')
    fi
    hostname=$(kubectl get deployers.knative.projectriff.io --namespace $NAMESPACE ${type_name} -o jsonpath='{$.status.url}' | sed -e 's|http://||g')

    curl ${ip}:${port} \
      -H "Host: ${hostname}" \
      -H "Content-Type: text/plain" \
      -d $input_data \
      -v | tee $type_name.out
  fi

  # add a new line after invoke, but without impacting the curl output
  echo ""
}

destroy_type() {
  local type=$1
  local type_name=$2
  local image=$3
  local runtime=${4:-core}

  echo "Destroy $type $type_name"

  riff $runtime deployer delete $type_name --namespace $NAMESPACE
  riff $type delete $type_name --namespace $NAMESPACE
  fats_delete_image $image
}

run_type() {
  local type=$1
  local path=$2
  local type_name=$3
  local image=$4
  local create_args=$5
  local input_data=$6
  local expected_data=$7
  local runtime=${8:-core}

  echo "Run $type $type_name"

  echo -e "${ANSI_BLUE}> path:${ANSI_RESET} ${path}"
  echo -e "${ANSI_BLUE}> name:${ANSI_RESET} ${type_name}"
  echo -e "${ANSI_BLUE}> image:${ANSI_RESET} ${image}"
  echo -e "${ANSI_BLUE}> args:${ANSI_RESET} ${create_args}"
  echo -e "${ANSI_BLUE}> runtime:${ANSI_RESET} ${runtime}"

  create_$type $path $type_name $image "$create_args" $runtime
  invoke_$type $type_name $input_data $expected_data $runtime
  destroy_$type $type_name $image $runtime

  local actual_data=`cat $type_name.out | tail -1`
  if [ "$actual_data" != "$expected_data" ]; then
    echo -e "${ANSI_RED}$type did not produce expected result${ANSI_RESET}:";
    echo -e "   expected: $expected_data"
    echo -e "   actual: $actual_data"
    exit 1
  fi
}
