#!/bin/bash

create_type() {
  local type=$1
  local path=$2
  local name=$3
  local image=$4
  local args=$5
  local runtime=${6:-core}

  echo "Create $type $name"

  pushd $path
    if [ -e '.fats/create' ]; then
      args="${args} `cat .fats/create`"
    fi

    # create function/application
    fats_echo "Creating $name:"
    riff $type create $name $args --image $image --namespace $NAMESPACE --tail &
    riff $runtime deployer create $name --$type-ref $name --namespace $NAMESPACE --tail

    # TODO reduce/eliminate this sleep
    sleep 5
  popd
}

invoke_type() {
  local type=$1
  local name=$2
  local curl_opts=$3
  local expected_data=$4
  local runtime=${5:-core}

  echo "Invoke $type $name"

  if [ $runtime = "core" ]; then
    svc=$(kubectl get deployers.core.projectriff.io --namespace $NAMESPACE ${name} -o jsonpath='{$.status.serviceName}')
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

    curl localhost:8080 ${curl_opts} -v | tee $name.out

    kill $pf_pid
  elif [ $runtime = "knative" ]; then
    ip=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.status.loadBalancer.ingress[0].ip}')
    port="80"
    if [ -z "$ip" ]; then
      ip=$(kubectl get node -o jsonpath='{$.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
      if [ -z "$ip" ] ; then
        ip=$(kubectl get node -o jsonpath='{$.items[0].status.addresses[?(@.type=="InternalIP")].address}')
      fi
      if [ -z "$ip" ] ; then
        ip=localhost
      fi
      port=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.spec.ports[?(@.name=="http2")].nodePort}')
    fi
    hostname=$(kubectl get deployers.knative.projectriff.io --namespace $NAMESPACE ${name} -o jsonpath='{$.status.url}' | sed -e 's|http://||g')

    curl ${ip}:${port} \
      -H "Host: ${hostname}" \
      $curl_opts \
      -v | tee $name.out
  fi

  # add a new line after invoke, but without impacting the curl output
  echo ""
}

destroy_type() {
  local type=$1
  local name=$2
  local image=$3
  local runtime=${4:-core}

  echo "Destroy $type $name"

  riff $runtime deployer delete $name --namespace $NAMESPACE
  riff $type delete $name --namespace $NAMESPACE
  fats_delete_image $image
}

run_type() {
  local type=$1
  local path=$2
  local name=$3
  local image=$4
  local create_args=$5
  local input_data=$6
  local expected_data=$7
  local runtime=${8:-core}

  echo "Run $type $name"

  echo -e "${ANSI_BLUE}> path:${ANSI_RESET} ${path}"
  echo -e "${ANSI_BLUE}> name:${ANSI_RESET} ${name}"
  echo -e "${ANSI_BLUE}> image:${ANSI_RESET} ${image}"
  echo -e "${ANSI_BLUE}> args:${ANSI_RESET} ${create_args}"
  echo -e "${ANSI_BLUE}> runtime:${ANSI_RESET} ${runtime}"

  create_$type $path $name $image "$create_args" $runtime
  invoke_$type $name $input_data $expected_data $runtime
  destroy_$type $name $image $runtime

  local actual_data=`cat $name.out | tail -1`
  if [ "$actual_data" != "$expected_data" ]; then
    echo -e "${ANSI_RED}$type did not produce expected result${ANSI_RESET}:";
    echo -e "   expected: $expected_data"
    echo -e "   actual: $actual_data"
    exit 1
  fi
}
