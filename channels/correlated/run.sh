#!/bin/bash

service_name=$1

function="uppercase"
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

  kail --ns $NAMESPACE --label "function=$function_name" > $function_name.logs &
  kail_function_pid=$!

  kail --ns knative-serving > $function_name.controller.logs &
  kail_controller_pid=$!

  riff function create $function_name $args --image $image --namespace $NAMESPACE
  riff channel create names --cluster-bus stub --namespace $NAMESPACE
  riff channel create replies --cluster-bus stub --namespace $NAMESPACE
  riff subscription create $function_name --channel names --subscriber $function_name --reply-to replies --namespace $NAMESPACE
  riff subscription create $service_name --channel replies --subscriber $service_name --namespace $NAMESPACE

  # wait for function deployment to be created
  selector="riff.projectriff.io/function=$function_name"
  fats_echo "Waiting for deployment labeled with $selector to be created:"
  wait_kube_selector_exists 'deployment.extensions' "$selector" "$NAMESPACE" "$function_name"

  # patch the cpu request for the function so it can start even if the available cpu is low
  deployment="$(kubectl get deployment --namespace $NAMESPACE -l $selector -oname)"
  fats_echo "Patching cpu request for $deployment"
  kubectl patch $deployment --namespace $NAMESPACE --patch "$(cat ./cpu-patch.yaml)"

  # wait for function to build and deploy
  fats_echo "Waiting for $function_name, channels and subscriptions to become ready:"
  wait_kservice_ready "${function_name}" $NAMESPACE
  wait_channel_ready 'names' $NAMESPACE
  wait_channel_ready 'replies' $NAMESPACE
  # TODO uncomment once subscriptions have a ready condition
  #wait_subscription_ready "$function_name" $NAMESPACE
  #wait_subscription_ready "$service_name" $NAMESPACE
  sleep 5

  riff service invoke $service_name /$NAMESPACE/names --namespace $NAMESPACE --text -- \
    -H "knative-blocking-request: true" \
    -w'\n' \
    -d $input_data | tee $function_name.out

  expected_data="RIFF"
  actual_data=`cat $function_name.out | tail -1`

  kill $kail_function_pid $kail_controller_pid
  riff subscription delete $function_name --namespace $NAMESPACE
  riff subscription delete $service_name --namespace $NAMESPACE
  riff channel delete names --namespace $NAMESPACE
  riff channel delete replies --namespace $NAMESPACE
  riff service delete $function_name --namespace $NAMESPACE

  fats_delete_image $image

  if [[ "$actual_data" != "$expected_data" ]]; then
    fats_echo "Function Logs:"
    cat $function_name.logs
    echo ""
    fats_echo "Controller Logs:"
    cat $function_name.controller.logs
    echo ""
    fats_echo "${RED}Function did not produce expected result${NC}";
    echo "   expected data: $expected_data"
    echo "   actual data: $actual_data"
    exit 1
  fi

popd
