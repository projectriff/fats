#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

test -z ${FATS_DIR-} && FATS_DIR=`dirname "${BASH_SOURCE[0]}"`/../..
source ${FATS_DIR}/.configure.sh

# install tools
${FATS_DIR}/install.sh riff
${FATS_DIR}/install.sh kubectl

NAMESPACE=${NAMESPACE-fats}
FATS_REPO=${FATS_REPO-projectriff/fats}
FATS_REFSPEC=${FATS_REFSPEC-master}
# setup namespace
kubectl create namespace ${NAMESPACE}
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
