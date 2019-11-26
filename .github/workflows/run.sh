#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ${FATS_DIR}/.configure.sh

# install tools
${FATS_DIR}/install.sh riff
${FATS_DIR}/install.sh kubectl

fats_create_push_credentials ${NAMESPACE}

# in cluster builds
# workaround for https://github.com/projectriff/node-function-invoker/issues/113
if [ ${CLUSTER} = "pks-gcp" ]; then
  languages="java java-boot command"
else
  languages="java java-boot node npm command"
fi
for test in ${languages}; do
  name=fats-cluster-uppercase-${test}
  image=$(fats_image_repo ${name})

  echo "##[group]Run function ${name}"

  riff function create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
    --git-repo https://github.com/${FATS_REPO} --git-revision ${FATS_REFSPEC} --sub-path functions/uppercase/${test} &
  riff core deployer create ${name} --function-ref ${name} --namespace ${NAMESPACE} --tail

  source ${FATS_DIR}/macros/invoke_core_deployer.sh ${name} "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS

  riff core deployer delete ${name} --namespace ${NAMESPACE}
  riff function delete ${name} --namespace ${NAMESPACE}
  fats_delete_image ${image}

  echo "##[endgroup]"
done

# local builds
if [ "${machine}" != "MinGw" ]; then
  # TODO enable for windows once we have a linux docker daemon available
  for test in ${languages}; do
    name=fats-local-uppercase-${test}
    image=$(fats_image_repo ${name})

    echo "##[group]Run function ${name}"

    riff function create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
      --local-path ${FATS_DIR}/functions/uppercase/${test} &
    riff knative deployer create ${name} --function-ref ${name} --namespace ${NAMESPACE} --tail

    source ${FATS_DIR}/macros/invoke_knative_deployer.sh ${name} "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS

    riff knative deployer delete ${name} --namespace ${NAMESPACE}
    riff function delete ${name} --namespace ${NAMESPACE}
    fats_delete_image ${image}

    echo "##[endgroup]"
  done
fi

for test in java-boot node; do
  name=fats-application-uppercase-${test}
  image=$(fats_image_repo ${name})

  echo "##[group]Run application ${name}"

  riff application create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
    --git-repo https://github.com/${FATS_REPO} --git-revision ${FATS_REFSPEC} --sub-path applications/uppercase/${test} &
  riff core deployer create ${name} --application-ref ${name} --namespace ${NAMESPACE} --tail

  source ${FATS_DIR}/macros/invoke_core_deployer.sh ${name} "--get --data-urlencode input=fats" FATS

  riff core deployer delete ${name} --namespace ${NAMESPACE}
  riff application delete ${name} --namespace ${NAMESPACE}
  fats_delete_image ${image}

  echo "##[endgroup]"
done

# test streaming
riff streaming kafka-provider create franz --bootstrap-servers my-kafka:9092 --namespace $NAMESPACE
for test in java java-boot; do
  name=fats-cluster-repeater-${test}
  image=$(fats_image_repo ${name})

  echo "##[group]Run function ${name}"

  riff function create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
    --git-repo https://github.com/${FATS_REPO} --git-revision ${FATS_REFSPEC} --sub-path functions/repeater/${test} &

  letters=${name}-letters
  numbers=${name}-numbers
  result=${name}-result

  riff streaming stream create ${letters} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'
  riff streaming stream create ${numbers} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'application/json'
  riff streaming stream create ${result} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'

  # TODO remove once riff streaming stream supports --tail
  kubectl wait streams.streaming.projectriff.io ${letters} --for=condition=Ready--namespace $NAMESPACE --timeout=60s
  kubectl wait streams.streaming.projectriff.io ${numbers} --for=condition=Ready--namespace $NAMESPACE --timeout=60s
  kubectl wait streams.streaming.projectriff.io ${result} --for=condition=Ready--namespace $NAMESPACE --timeout=60s

  riff streaming processor create $name --function-ref $name --namespace $NAMESPACE --input ${letters} --input ${numbers} --output ${result} --tail

  kubectl exec dev-utils -n $NAMESPACE -- subscribe ${result} -n $NAMESPACE --payload-as-string > result.txt &
  kubectl exec dev-utils -n $NAMESPACE -- publish ${letters} -n $NAMESPACE --payload foo --content-type "text/plain"
  kubectl exec dev-utils -n $NAMESPACE -- publish ${numbers} -n $NAMESPACE --payload 2 --content-type "application/json"

  verify_payload result.txt "[foo foo]"

  riff streaming stream delete ${numbers} --namespace $NAMESPACE
  riff streaming stream delete ${letters} --namespace $NAMESPACE
  riff streaming stream delete ${results} --namespace $NAMESPACE
  riff streaming processor delete $name --namespace $NAMESPACE
  riff function delete ${name} --namespace ${NAMESPACE}
  fats_delete_image ${image}
done
riff streaming kafka-provider delete franz --namespace $NAMESPACE
