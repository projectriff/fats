#!/bin/bash

create_function() {
  path=$1
  function_name=$2
  image=$3

  pushd $path
    args=""
    if [ -e '.fats/create' ]; then
      args=`cat .fats/create`
    fi

    # create function
    fats_echo "Creating $function_name:"
    riff function create $function_name $args --image $image --namespace $NAMESPACE --verbose

    # TODO reduce/eliminate this sleep
    sleep 5
  popd
}

invoke_function() {
  function_name=$1
  input_data=$2
  expected_data=$3

  fats_echo "Invoking $function_name:"
  riff service invoke $function_name --namespace $NAMESPACE -- \
    -H "Content-Type: text/plain" \
    -d $input_data \
    -v | tee $function_name.out

  # add a new line after invoke, but without impacting the curl output
  echo ""
}

destroy_function() {
  function_name=$1
  image=$2

  riff service delete $function_name --namespace $NAMESPACE
  fats_delete_image $image
}

run_function() {
  path=$1
  function_name=$2
  image=$3
  input_data=$4
  expected_data=$5

  travis_fold start function-$function_name

  kail --ns $NAMESPACE --label "function=$function_name" > $function_name.logs &
  kail_function_pid=$!

  kail --ns knative-serving > $function_name.controller.logs &
  kail_controller_pid=$!

  create_function $path $function_name $image

  invoke_function $function_name $input_data $expected_data

  # cleanup resources
  kill $kail_function_pid $kail_controller_pid
  destroy_function $function_name $image

  actual_data=`cat $function_name.out | tail -1`
  if [ "$actual_data" != "$expected_data" ]; then
    fats_echo "Function Logs:"
    cat $function_name.logs
    echo ""
    fats_echo "Controller Logs:"
    cat $function_name.controller.logs
    echo ""
    fats_echo "${ANSI_RED}Function did not produce expected result${ANSI_RESET}:";
    echo "   expected: $expected_data"
    echo "   actual: $actual_data"
    exit 1
  fi

  travis_fold end function-$function_name
}
