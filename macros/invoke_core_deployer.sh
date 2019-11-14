#!/bin/bash

set -o nounset

name=$1
curl_opts=$2
expected_data=$3

echo "Invoke core deployer $name"

svc=$(kubectl get deployers.core.projectriff.io --namespace $NAMESPACE ${name} -o jsonpath='{$.status.serviceName}')
kubectl port-forward --namespace $NAMESPACE service/${svc} 8080:80 &
pf_pid=$!

# wait for the port-forward to be ready
if [ -x "$(command -v nc)" ]; then
  while ! nc -z localhost 8080; do
    sleep 1
  done
  sleep 2
else
  sleep 5
fi

curl localhost:8080 ${curl_opts} -v | tee $name.out

actual_data=$(cat $name.out | tail -1)
rm $name.out

kill $pf_pid

# add a new line after invoke, but without impacting the curl output
echo ""

if [ "$actual_data" != "$expected_data" ]; then
  echo -e "${ANSI_RED}did not produce expected result${ANSI_RESET}:";
  echo -e "   expected: $expected_data"
  echo -e "   actual: $actual_data"
  exit 1
fi
