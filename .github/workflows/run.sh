#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ${FATS_DIR}/.configure.sh

# install tools
${FATS_DIR}/install.sh riff
${FATS_DIR}/install.sh kubectl

kubectl create ns $NAMESPACE
fats_create_push_credentials ${NAMESPACE}
source ${FATS_DIR}/macros/create-riff-dev-pod.sh
riff streaming kafka-provider create franz --bootstrap-servers kafka.kafka.svc.cluster.local:9092 --namespace $NAMESPACE

# streaming runtime (debug)
riff streaming stream create echo --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'
kubectl wait streams.streaming.projectriff.io echo --for=condition=Ready --namespace $NAMESPACE --timeout=60s
kubectl exec riff-dev -n $NAMESPACE -- subscribe echo -n $NAMESPACE --payload-as-string > result.txt &
kubectl exec riff-dev -n $NAMESPACE -- publish echo -n $NAMESPACE --payload "fats" --content-type "text/plain"
verify_payload result.txt "fats"
kubectl exec riff-dev -n $NAMESPACE -- sh -c 'kill $(pidof subscribe)'
riff streaming stream delete echo --namespace $NAMESPACE



if [ "${machine}" != "MinGw" ]; then
  modes="cluster local"
else
  modes="cluster"
fi

# workaround for https://github.com/projectriff/node-function-invoker/issues/113
if [ ${CLUSTER} = "pks-gcp" ]; then
  languages="command java java-boot"
else
  languages="command node npm java java-boot"
fi
for mode in ${modes}; do
  # functions
  for test in ${languages}; do
    name=fats-${mode}-fn-uppercase-${test}
    image=$(fats_image_repo ${name})

    echo "##[group]Run function ${name}"

    if [ "${mode}" == "cluster" ]; then
      riff function create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
        --git-repo https://github.com/${FATS_REPO} --git-revision ${FATS_REFSPEC} --sub-path functions/uppercase/${test}
    elif [ "${mode}" == "local" ]; then
      riff function create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
        --local-path ${FATS_DIR}/functions/uppercase/${test}
    else
      echo "Unknown mode: ${mode}"
      exit 1
    fi

    # core runtime
    riff core deployer create ${name} --function-ref ${name} --namespace ${NAMESPACE} --tail
    source ${FATS_DIR}/macros/invoke_core_deployer.sh ${name} "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS
    riff core deployer delete ${name} --namespace ${NAMESPACE}

    # knative runtime
    riff knative deployer create ${name} --function-ref ${name} --namespace ${NAMESPACE} --tail
    source ${FATS_DIR}/macros/invoke_knative_deployer.sh ${name} "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS
    riff knative deployer delete ${name} --namespace ${NAMESPACE}

    # streaming runtime
    lower_stream=${name}-lower
    upper_stream=${name}-upper

    riff streaming stream create ${lower_stream} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'
    riff streaming stream create ${upper_stream} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'

    # TODO remove once riff streaming stream supports --tail
    kubectl wait streams.streaming.projectriff.io ${lower_stream} --for=condition=Ready --namespace $NAMESPACE --timeout=60s
    kubectl wait streams.streaming.projectriff.io ${upper_stream} --for=condition=Ready --namespace $NAMESPACE --timeout=60s

    riff streaming processor create $name --function-ref $name --namespace $NAMESPACE --input ${lower_stream} --output ${upper_stream}
    riff streaming processor tail $name --namespace $NAMESPACE > processor.log &
    processor_pid=$?
    kubectl wait processors.streaming.projectriff.io $name --for=condition=Ready --namespace $NAMESPACE --timeout=60s

    kubectl exec riff-dev -n $NAMESPACE -- subscribe ${upper_stream} -n $NAMESPACE --payload-as-string | tee result.txt &
    kubectl exec riff-dev -n $NAMESPACE -- publish ${lower_stream} -n $NAMESPACE --payload "fats" --content-type "text/plain"

    actual_data=""
    expected_data="FATS"
    cnt=1
    while [ $cnt -lt 60 ] && [ $expected_data != $actual_data ]; do
      sleep 1
      cnt=$((cnt+1))

      actual_data=`cat result.txt | jq -r .payload`
      echo -n "."
    done

    kill $processor_pid
    echo ""
    echo "Processor log:"
    cat processor.log
    echo ""

    if [ "$actual_data" != "$expected_data" ]; then
      echo -e "${ANSI_RED}did not produce expected result${ANSI_RESET}:";
      echo -e "   expected: $expected_data"
      echo -e "   actual: $actual_data"
      exit 1
    fi

    kubectl exec riff-dev -n $NAMESPACE -- sh -c 'kill $(pidof subscribe)'

    riff streaming stream delete ${lower_stream} --namespace $NAMESPACE
    riff streaming stream delete ${upper_stream} --namespace $NAMESPACE
    riff streaming processor delete $name --namespace $NAMESPACE

    # cleanup
    riff function delete ${name} --namespace ${NAMESPACE}
    fats_delete_image ${image}

    echo "##[endgroup]"
  done

  # applications
  for test in ${languages}; do
    name=fats-${mode}-app-uppercase-${test}
    image=$(fats_image_repo ${name})

    echo "##[group]Run application ${name}"

    if [ "${mode}" == "cluster" ]; then
      riff application create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
        --git-repo https://github.com/${FATS_REPO} --git-revision ${FATS_REFSPEC} --sub-path applications/uppercase/${test}
    elif [ "${mode}" == "local" ]; then
      riff application create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
        --local-path ${FATS_DIR}/applications/uppercase/${test}
    else
      echo "Unknown mode: ${mode}"
      exit 1
    fi

    # core runtime
    riff core deployer create ${name} --application-ref ${name} --namespace ${NAMESPACE} --tail
    source ${FATS_DIR}/macros/invoke_core_deployer.sh ${name} "--get --data-urlencode input=fats" FATS
    riff core deployer delete ${name} --namespace ${NAMESPACE}

    # knative runtime
    riff knative deployer create ${name} --application-ref ${name} --namespace ${NAMESPACE} --tail
    source ${FATS_DIR}/macros/invoke_knative_deployer.sh ${name} "--get --data-urlencode input=fats" FATS
    riff knative deployer delete ${name} --namespace ${NAMESPACE}

    # cleanup
    riff application delete ${name} --namespace ${NAMESPACE}
    fats_delete_image ${image}

    echo "##[endgroup]"
  done
done

riff streaming kafka-provider delete franz --namespace $NAMESPACE
