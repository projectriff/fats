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
source ${FATS_DIR}/macros/install-dev-utils.sh
riff streaming kafka-provider create franz --bootstrap-servers kafka.kafka.svc.cluster.local:9092 --namespace $NAMESPACE

# in cluster builds
# workaround for https://github.com/projectriff/node-function-invoker/issues/113
if [ ${CLUSTER} = "pks-gcp" ]; then
  languages="command java java-boot"
else
  languages="command node npm java java-boot"
fi
if [ "${machine}" != "MinGw" ]; then
  modes="cluster local"
else
  modes="cluster"
fi
for mode in ${modes}; do
  for test in ${languages}; do
    name=fats-${mode}-uppercase-${test}
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
    input=${name}-input
    output=${name}-output

    riff streaming stream create ${input} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'
    riff streaming stream create ${output} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'

    # TODO remove once riff streaming stream supports --tail
    kubectl wait streams.streaming.projectriff.io ${input} --for=condition=Ready--namespace $NAMESPACE --timeout=60s
    kubectl wait streams.streaming.projectriff.io ${output} --for=condition=Ready--namespace $NAMESPACE --timeout=60s

    riff streaming processor create $name --function-ref $name --namespace $NAMESPACE --input ${input} --output ${output} --tail

    kubectl exec dev-utils -n $NAMESPACE -- subscribe ${output} -n $NAMESPACE --payload-as-string > result.txt &
    kubectl exec dev-utils -n $NAMESPACE -- publish ${input} -n $NAMESPACE --payload "fats" --content-type "text/plain"

    verify_payload result.txt "FATS"

    riff streaming stream delete ${input} --namespace $NAMESPACE
    riff streaming stream delete ${output} --namespace $NAMESPACE
    riff streaming processor delete $name --namespace $NAMESPACE

    # cleanup
    riff function delete ${name} --namespace ${NAMESPACE}
    fats_delete_image ${image}

    echo "##[endgroup]"
  done
done

riff streaming kafka-provider delete franz --namespace $NAMESPACE
