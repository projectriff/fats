#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`
function=`basename $dir`

for invoker in command go java node python3; do
  pushd $dir/$invoker
    function_name="fats-$function-$invoker"
    function_version="${CLUSTER_NAME}"
    useraccount="gcr.io/`gcloud config get-value project`"
    input_data="hello"

    args=""
    if [ -e 'create' ]; then
      args=`cat create`
    fi

    kail --label "function=$function_name" > $function_name.logs &
    kail_function_pid=$!

    kail --label app=riff --ns riff-system > $function_name.controller.logs &
    kail_controller_pid=$!

    riff create $args \
      --useraccount $useraccount \
      --name $function_name \
      --version $function_version \
      --push

    riff publish \
      --input $function_name \
      --data $input_data \
      --reply \
      | tee $function_name.out

    expected_data="HELLO"
    actual_data=`cat $function_name.out | tail -1`

    kill $kail_function_pid $kail_controller_pid
    riff delete --all --name $function_name
    gcloud container images delete "${useraccount}/${function_name}:${function_version}"

    if [ "$actual_data" != "$expected_data" ]; then
      echo -e "Function Logs:"
      cat $function_name.logs
      echo -e ""
      echo -e "Controller Logs:"
      cat $function_name.controller.logs
      echo -e ""
      echo -e "${RED}Function did not produce expected result${NC}";
      echo -e "   expected: $expected_data"
      echo -e "   actual: $actual_data"
      exit 1
    fi
  popd
done
