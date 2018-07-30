#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`
function=`basename $dir`

for invoker in java node; do
  pushd $dir/$invoker
    function_name="fats-$function-$invoker"
    function_version="${CLUSTER_NAME}"
    useraccount="gcr.io/`gcloud config get-value project`"
    image="${useraccount}/${function_name}:${function_version}"
    input_data="hello"

    args=""
    if [ -e 'create' ]; then
      args=`cat create`
    fi

    kail --label "function=$function_name" > $function_name.logs &
    kail_function_pid=$!

    kail --ns knative-serving > $function_name.controller.logs &
    kail_controller_pid=$!

    # create function
    riff function create $invoker $function_name $args \
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
    gcloud container images delete $image

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
