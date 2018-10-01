#!/bin/bash

service_name=$1

function="hello"
invoker="node"

pushd "functions/$function/$invoker"
  function_name="fats-$function-$invoker"
  function_version="${CLUSTER_NAME}"
  image="${USER_ACCOUNT}/${function_name}:${function_version}"
  input_data="riff"

  args=""
  if [ -e '.fats/create' ]; then
    args=`cat .fats/create`
  fi

  if [ -e '.fats/invoker' ]; then
    # overwrite invoker
    invoker=`cat .fats/invoker`
  fi

  kail --label "function=$function_name" > $function_name.logs &
  kail_function_pid=$!

  kail --ns knative-serving > $function_name.controller.logs &
  kail_controller_pid=$!

  riff function create $invoker $function_name $args --image $image --wait --verbose
  riff channel create names --cluster-bus stub
  riff channel create hellonames --cluster-bus stub
  riff subscription create $function_name --subscriber $function_name --channel names --reply-to hellonames
  riff subscription create $service_name --subscriber $service_name --channel hellonames

  riff service invoke $service_name /names --text -- \
    -H "knative-blocking-request: true" \
    -w'\n' \
    -d $input_data | tee $function_name.out

  expected_data_prefix="hello riff from"
  actual_data=`cat $function_name.out | tail -1`

  kill $kail_function_pid $kail_controller_pid
  riff subscription delete $function_name
  riff subscription delete $service_name
  riff channel delete names
  riff channel delete hellonames
  riff service delete $function_name

  fats_delete_image $image

  if [[ "$actual_data" != $expected_data_prefix* ]]; then
    echo -e "Function Logs:"
    cat $function_name.logs
    echo -e ""
    echo -e "Controller Logs:"
    cat $function_name.controller.logs
    echo -e ""
    echo -e "${RED}Function did not produce expected result${NC}";
    echo -e "   expected prefix: $expected_data_prefix"
    echo -e "   actual data: $actual_data"
    exit 1
  fi

popd
