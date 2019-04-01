#!/bin/bash

create_function() {
  local path=$1
  local function_name=$2
  local image=$3
  local args=$4

  travis_fold start create-function-$function_name
  echo "Create function $function_name"

  pushd $path
    if [ -e '.fats/create' ]; then
      args="${args} `cat .fats/create`"
    fi

    # create function
    fats_echo "Creating $function_name:"
    riff function create $function_name $args --image $image --namespace $NAMESPACE --verbose

    # TODO reduce/eliminate this sleep
    sleep 5
  popd

  travis_fold end create-function-$function_name
}

invoke_function() {
  local function_name=$1
  local input_data=$2
  local expected_data=$3

  travis_fold start invoke-function-$function_name
  echo "Invoke function $function_name"

  riff service invoke $function_name --namespace $NAMESPACE -- \
    -H "Content-Type: text/plain" \
    -d $input_data \
    -v | tee $function_name.out

  # add a new line after invoke, but without impacting the curl output
  echo ""

  travis_fold end invoke-function-$function_name
}

destroy_function() {
  local function_name=$1
  local image=$2

  travis_fold start destroy-function-$function_name
  echo "Destroy function $function_name"

  riff service delete $function_name --namespace $NAMESPACE
  fats_delete_image $image

  travis_fold end destroy-function-$function_name
}

run_function() {
  local path=$1
  local function_name=$2
  local image=$3
  local create_args=$4
  local input_data=$5
  local expected_data=$6

  travis_fold start function-$function_name
  echo "Run function $function_name"

  echo -e "${ANSI_BLUE}> path:${ANSI_RESET} ${path}"
  echo -e "${ANSI_BLUE}> name:${ANSI_RESET} ${function_name}"
  echo -e "${ANSI_BLUE}> image:${ANSI_RESET} ${image}"
  echo -e "${ANSI_BLUE}> args:${ANSI_RESET} ${create_args}"

  kail --ns $NAMESPACE --label "function=$function_name" > $function_name.logs 2>&1 &
  local kail_function_pid=$!

  kail --ns knative-serving > $function_name.controller.logs 2>&1 &
  local kail_controller_pid=$!

  create_function $path $function_name $image "$create_args"

  invoke_function $function_name $input_data $expected_data

  # cleanup resources
  kill $kail_function_pid $kail_controller_pid || true
  destroy_function $function_name $image

  local actual_data=`cat $function_name.out | tail -1`
  if [ "$actual_data" != "$expected_data" ]; then
    travis_fold start function-$function_name-logs-function
    echo -e "Function Logs:"
    cat $function_name.logs
    travis_fold end function-$function_name-logs-function
    echo -e ""
    travis_fold start function-$function_name-logs-controller
    echo -e "Controller Logs:"
    cat $function_name.controller.logs
    travis_fold end function-$function_name-logs-controller
    echo -e ""
    echo -e "${ANSI_RED}Function did not produce expected result${ANSI_RESET}:";
    echo -e "   expected: $expected_data"
    echo -e "   actual: $actual_data"
    exit 1
  fi

  travis_fold end function-$function_name
}
