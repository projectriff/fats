#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`
function=`basename $dir`
date="date -u +%Y-%m-%dT%H:%M:%SZ"

for invoker in command jar java java-local node; do
  pushd $dir/$invoker
    function_name="fats-$function-$invoker"
    function_version="${CLUSTER_NAME}"
    image="${USER_ACCOUNT}/${function_name}:${function_version}"
    input_data="hello"

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

    # create function
    echo "[`$date`] Creating $function_name as $invoker:"
    riff function create $invoker $function_name $args --image $image

    # wait for function to build and deploy
    echo "[`$date`] Waiting for $function_name to become ready:"
     until kube_ready \
      'services.serving.knative.dev' \
      'default' \
      "${function_name}" \
      ';{range @.status.conditions[*]}{@.type}={@.status};{end}' \
      ';Ready=True;' \
    ; do sleep 1; done
    sleep 5

    # invoke function
    echo "[`$date`] Invoking $function_name:"
    riff service invoke $function_name -- \
      -H "Content-Type: text/plain" \
      -d $input_data \
      -v | tee $function_name.out

    # add a new line after invoke, but without impacting the curl output
    echo ""

    expected_data="HELLO"
    actual_data=`cat $function_name.out | tail -1`

    # cleanup resources
    kill $kail_function_pid $kail_controller_pid
    riff service delete $function_name
    fats_delete_image $image

    if [ "$actual_data" != "$expected_data" ]; then
      echo -e "Function Logs:"
      cat $function_name.logs
      echo -e ""
      echo -e "Controller Logs:"
      cat $function_name.controller.logs
      echo -e ""
      echo -e "[`$date`] ${RED}Function did not produce expected result${NC}:";
      echo -e "   expected: $expected_data"
      echo -e "   actual: $actual_data"
      exit 1
    fi
  popd
done
