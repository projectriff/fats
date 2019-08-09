#!/bin/bash

create_function() {
  local path=$1
  local function_name=$2
  local image=$3
  local args=$4

  echo "Create function $function_name"

  pushd $path
    if [ -e '.fats/create' ]; then
      args="${args} `cat .fats/create`"
    fi

    # create function
    fats_echo "Creating $function_name:"
    riff function create $function_name $args --image $image --namespace $NAMESPACE --tail &
    riff knative deployer create $function_name --function-ref $function_name --namespace $NAMESPACE --tail

    # TODO reduce/eliminate this sleep
    sleep 5
  popd
}

invoke_function() {
  local function_name=$1
  local input_data=$2
  local expected_data=$3

  echo "Invoke function $function_name"

  riff knative deployer invoke $function_name --namespace $NAMESPACE -- \
    -H "Content-Type: text/plain" \
    -d $input_data \
    -v | tee $function_name.out

  # add a new line after invoke, but without impacting the curl output
  echo ""
}

destroy_function() {
  local function_name=$1
  local image=$2

  echo "Destroy function $function_name"

  riff knative deployer delete $function_name --namespace $NAMESPACE
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

  echo "Run function $function_name"

  echo -e "${ANSI_BLUE}> path:${ANSI_RESET} ${path}"
  echo -e "${ANSI_BLUE}> name:${ANSI_RESET} ${function_name}"
  echo -e "${ANSI_BLUE}> image:${ANSI_RESET} ${image}"
  echo -e "${ANSI_BLUE}> args:${ANSI_RESET} ${create_args}"

  create_function $path $function_name $image "$create_args"
  invoke_function $function_name $input_data $expected_data
  destroy_function $function_name $image

  local actual_data=`cat $function_name.out | tail -1`
  if [ "$actual_data" != "$expected_data" ]; then
    echo -e "${ANSI_RED}Function did not produce expected result${ANSI_RESET}:";
    echo -e "   expected: $expected_data"
    echo -e "   actual: $actual_data"
    exit 1
  fi
}
