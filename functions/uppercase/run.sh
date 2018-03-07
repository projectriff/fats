#!/bin/bash		
		
set -o errexit		
set -o nounset		
set -o pipefail		

dir=`dirname "${BASH_SOURCE[0]}"`
function=`basename $dir`
cluster=$1
riffVersion=$2

# TODO enable python2 after projectriff/python2-function-invoker#1
for invoker in java node shell; do
    echo $invoker
    pushd $dir/$invoker
        name="fats-$function-$invoker"
        useraccount="gcr.io/`gcloud config get-value project`"
        version="${riffVersion}-${cluster}"
        args=""
        input="hello"
        expected="HELLO"
        if [ -e 'create' ]; then
            args=`cat create`
        fi
        riff create $args --useraccount $useraccount --name $name --version $version --riff-version $riffVersion --push
        riff publish --input $name --data hello --reply | tee $name.out
        actual=`cat $name.out | tail -1`
        riff delete --all --name $name
        gcloud container images delete "${useraccount}/${name}:${version}" --quiet
        if [ "$actual" != "$expected" ]; then
            echo "Function did not produce expected result";
            echo "   expected: $expected"
            echo "   actual: $actual"
            exit 1
        fi
    popd
done