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

  riff function create $invoker $function_name $args --image $image
  riff channel create names --cluster-bus stub
  riff channel create replies --cluster-bus stub
  riff subscription create $function_name --channel names --subscriber $function_name --reply-to replies
  riff subscription create $service_name --channel replies --subscriber $service_name

  # wait for function to build and deploy
  fats_echo "Waiting for $function_name, channels and subscriptions to become ready:"
  until kservice_ready "${function_name}" 'default'; do sleep 1; done
  until channel_ready 'names' 'default'; do sleep 1; done
  until channel_ready 'replies' 'default'; do sleep 1; done
  until subscription_ready "$function_name" 'default'; do sleep 1; done
  until subscription_ready "$service_name" 'default'; do sleep 1; done

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
  riff channel delete replies
  riff service delete $function_name

  fats_delete_image $image

  if [[ "$actual_data" != $expected_data_prefix* ]]; then
    fats_echo "Function Logs:"
    cat $function_name.logs
    echo ""
    fats_echo "Controller Logs:"
    cat $function_name.controller.logs
    echo ""
    fats_echo "${RED}Function did not produce expected result${NC}";
    echo "   expected prefix: $expected_data_prefix"
    echo "   actual data: $actual_data"
    exit 1
  fi

popd
