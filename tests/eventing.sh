#!/bin/bash

# TODO make FATS channel tests modular enough to use here

travis_fold start eventing
echo "Eventing"

test_name=echo

kail --ns $NAMESPACE > $test_name.logs 2>&1 &
kail_test_pid=$!

kail --ns knative-serving --ns knative-eventing > $test_name.controller.logs 2>&1 &
kail_controller_pid=$!

kubectl apply -f https://storage.googleapis.com/knative-releases/eventing-sources/previous/v0.3.0/release.yaml
wait_pod_selector_ready control-plane=controller-manager knative-sources

kubectl apply -n $NAMESPACE -f https://storage.googleapis.com/knative-releases/eventing-sources/previous/v0.3.0/message-dumper.yaml
wait_kservice_ready message-dumper $NAMESPACE

kail --ns $NAMESPACE --label serving.knative.dev/service=message-dumper -c user-container > $test_name.output.logs 2>&1 &
kail_output_pid=$!

riff channel create $test_name --namespace $NAMESPACE
riff subscription create $test_name --channel $test_name --subscriber message-dumper --namespace $NAMESPACE

wait_channel_ready $test_name $NAMESPACE
wait_subscription_ready $test_name $NAMESPACE

cat <<EOF | kubectl apply -f -
apiVersion: sources.eventing.knative.dev/v1alpha1
kind: CronJobSource
metadata:
  name: test-cronjob-source
  namespace: $NAMESPACE
spec:
  schedule: '* * * * *'
  data: '{"message": "Hello world!"}'
  sink:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: Channel
    name: $test_name
EOF
echo "step 1"
wait_knative_ready cronjobsource.sources.eventing.knative.dev test-cronjob-source $NAMESPACE
echo "step 2"

# cron source triggers once a minute
sleep 75
echo "step 3"

expected_data="0"
actual_data=$(cat $test_name.output.logs | grep 'Hello world!' | wc -l)
echo "step 4"

kill $kail_output_pid $kail_test_pid $kail_controller_pid || true
echo "step 5"
riff subscription delete $test_name --namespace $NAMESPACE
echo "step 6"
riff channel delete $test_name --namespace $NAMESPACE
echo "step 7"
riff service delete message-dumper --namespace $NAMESPACE
echo "step 8"
kubectl delete cronjobsource.sources.eventing.knative.dev test-cronjob-source -n $NAMESPACE
echo "step 9"

kubectl delete ns knative-sources
echo "step 10"

if [[ "$actual_data" == "$expected_data" ]]; then
  # negative test since we'll get no matching output by default
  fats_echo "Dumper Logs:"
  cat $test_name.output.logs
  echo ""
  fats_echo "Test Logs:"
  cat $test_name.logs
  echo ""
  fats_echo "Controller Logs:"
  cat $test_name.controller.logs
  echo ""
  fats_echo "${ANSI_RED}Test did not produce expected result${ANSI_RESET}";
  echo "   expected data: $expected_data"
  echo "   actual data: $actual_data"
  exit 1
fi

echo "step 11"
travis_fold end eventing
echo "step 12"
