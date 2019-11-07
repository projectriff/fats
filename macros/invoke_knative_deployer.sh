#!/bin/bash

name=$1
curl_opts=$2
expected_data=$3

echo "Invoke knative deployer $name"

ip=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.status.loadBalancer.ingress[0].ip}')
port="80"
if [ -z "$ip" ]; then
  ip=$(kubectl get node -o jsonpath='{$.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
  if [ -z "$ip" ] ; then
    ip=$(kubectl get node -o jsonpath='{$.items[0].status.addresses[?(@.type=="InternalIP")].address}')
  fi
  if [ -z "$ip" ] ; then
    ip=localhost
  fi
  port=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{$.spec.ports[?(@.name=="http2")].nodePort}')
fi
hostname=$(kubectl get deployers.knative.projectriff.io --namespace $NAMESPACE ${name} -o jsonpath='{$.status.url}' | sed -e 's|http://||g')

curl ${ip}:${port} \
  -H "Host: ${hostname}" \
  $curl_opts \
  -v | tee $name.out

actual_data=$(cat $name.out | tail -1)
rm $name.out

# add a new line after invoke, but without impacting the curl output
echo ""

if [ "$actual_data" != "$expected_data" ]; then
  echo -e "${ANSI_RED}did not produce expected result${ANSI_RESET}:";
  echo -e "   expected: $expected_data"
  echo -e "   actual: $actual_data"
  exit 1
fi
