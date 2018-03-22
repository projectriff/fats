#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`
function_name=`basename $dir`

for invoker in java; do
  pushd $dir/$invoker
    riff delete --all
    rm *.yaml
    rm Dockerfile
  
    kubectl delete deploy echoheaders 
  
    ./mvnw clean package
  
    riff create java \
    --name echoheaders \
    --artifact target/echo-headers-1.0.0.jar \
    --handler io.projectriff.fats.EchoHeaders \
    --force 
  
    # This seems more difficult than it should be.
    nodeport=$(kubectl get svc \
      --all-namespaces \
      -l app=riff,component=http-gateway \
      --output=jsonpath='{.items[0].spec.ports[?(@.name == "http")].nodePort}')

    # Can't use riff publish here because I want to set custom headers.
    echo -----------------------------
    curl \
    --header "Echo-Header: echoheader" \
    --data "body=echobody" \
    -X POST http://192.168.99.100:$nodeport/requests/echoheaders \
      | tee $function_name.out

    echo
    echo -----------------------------
    echo

    expected_data="Echo-Header=echoheader"
    actual_data=`cat $function_name.out | head -2 | tail -1`

    if [[ "$actual_data" != *"$expected_data"* ]]; then
      echo -e "${RED}Function did not produce include expected header${NC}";
      echo -e "   expected: $expected_data"
      echo -e "   actual: $actual_data"
      exit 1
    fi
  popd

  echo "Success!"  
done
