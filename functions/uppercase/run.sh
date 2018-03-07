#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`
function=`basename $dir`

# TODO enable python2 after projectriff/python2-function-invoker#1
for invoker in java node shell; do
    echo $invoker
    pushd $dir/$invoker
        function_name="fats-$function-$invoker"
        function_version="${CLUSTER_NAME}"
        useraccount="gcr.io/`gcloud config get-value project`"
        input_data="hello"

        args=""
        if [ -e 'create' ]; then
            args=`cat create`
        fi

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

        riff delete --all --name $function_name
        gcloud container images delete "${useraccount}/${function_name}:${function_version}" --quiet

        if [ "$actual_data" != "$expected_data" ]; then
            echo "Function did not produce expected result";
            echo "   expected: $expected_data"
            echo "   actual: $actual_data"
            exit 1
        fi
    popd
done
