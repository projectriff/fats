#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`
function=`basename $dir`

for runtime in command java java-buildpack java-buildpack-local node; do
  pushd $dir/$runtime
    function_name="fats-$function-$runtime"
    function_version="${CLUSTER_NAME}"
    image="${USER_ACCOUNT}/${function_name}:${function_version}"
    input_data="hello"

    args=""
    if [ -e '.fats/create' ]; then
      args=`cat .fats/create`
    fi

    if [ -e '.fats/runtime' ]; then
      # overwrite runtime
      runtime=`cat .fats/runtime`
    fi

    kail --label "function=$function_name" > $function_name.logs &
    kail_function_pid=$!

    kail --ns knative-serving > $function_name.controller.logs &
    kail_controller_pid=$!

    # create function
    riff function create $runtime $function_name $args \
      --image $image

    # wait for function to build and deploy
    echo "Waiting for function to become ready"
    until kube_ready \
      'pods' \
      'default' \
      "serving.knative.dev/configuration=${function_name}" \
      '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
      'Ready=True' \
    ; do sleep 1; done
    # TODO reduce/eliminate this sleep
    sleep 10

    # invoke function
    riff service invoke $function_name -- \
      -H "Content-Type: text/plain" \
      -d $input_data \
      -v | tee $function_name.out

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
      echo -e "${RED}Function did not produce expected result${NC}";
      echo -e "   expected: $expected_data"
      echo -e "   actual: $actual_data"
      exit 1
    fi
  popd
done
