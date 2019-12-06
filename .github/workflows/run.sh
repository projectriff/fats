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

if [ "${machine}" != "MinGw" ]; then
  modes="cluster local"
else
  modes="cluster"
fi


for mode in ${modes}; do
  # functions
  # workaround for https://github.com/projectriff/node-function-invoker/issues/113
  if [ ${CLUSTER} = "pks-gcp" ]; then
    languages="command java java-boot"
  else
    languages="java java-boot"
    # languages="command node npm java java-boot"
  fi
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

  #   # core runtime
  #   riff core deployer create ${name} --function-ref ${name} --ingress-policy ClusterLocal --namespace ${NAMESPACE} --tail
  #   source ${FATS_DIR}/macros/invoke_core_deployer.sh ${name} "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS
  #   riff core deployer delete ${name} --namespace ${NAMESPACE}

  #   # knative runtime
  #   riff knative deployer create ${name} --function-ref ${name} --ingress-policy External --namespace ${NAMESPACE} --tail
  #   source ${FATS_DIR}/macros/invoke_knative_deployer.sh ${name} "-H Content-Type:text/plain -H Accept:text/plain -d fats" FATS
  #   riff knative deployer delete ${name} --namespace ${NAMESPACE}

    # TODO enable streaming tests
    # streaming runtime
    if [ "$test" != "commnd" ]; then
      lower_stream=${test}-lower
      upper_stream=${test}-upper

      set -x
      riff streaming stream create ${lower_stream} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'
      riff streaming stream create ${upper_stream} --namespace $NAMESPACE --provider franz-kafka-provisioner --content-type 'text/plain'

      # TODO remove once riff streaming stream supports --tail
      kubectl wait streams.streaming.projectriff.io ${lower_stream} --for=condition=Ready --namespace $NAMESPACE --timeout=60s
      kubectl wait streams.streaming.projectriff.io ${upper_stream} --for=condition=Ready --namespace $NAMESPACE --timeout=60s

      processor=uppercase-${test}
      riff streaming processor create ${processor} --function-ref $name --namespace $NAMESPACE --input ${lower_stream} --output ${upper_stream} --tail
      # kubectl get processors.streaming.projectriff.io ${processor} --namespace $NAMESPACE --watch &
      #kubectl wait processors.streaming.projectriff.io ${processor} --for=condition=Ready --namespace $NAMESPACE --timeout=60s
      # kubectl get scaledobjects.keda.k8s.io --selector streaming.projectriff.io/processor --namespace $NAMESPACE -o custom-columns='NAME:.metadata.name,LAST ACTIVE:.status.lastActiveTime' --watch &
      
      # sleep 20
      kubectl exec riff-dev -n $NAMESPACE -- subscribe ${upper_stream} -n $NAMESPACE --payload-as-string | tee result.txt &
      #sleep 10
      kubectl exec riff-dev -n $NAMESPACE -- publish ${lower_stream} -n $NAMESPACE --payload "fats" --content-type "text/plain"
      # wait_pod_selector_ready "streaming.projectriff.io/processor=${processor}" $NAMESPACE

      set +x
      actual_data=""
      expected_data="FATS"
      cnt=1
      while [ $cnt -lt 60 ]; do
        echo -n "."
        cnt=$((cnt+1))

        actual_data=`cat result.txt | jq -r .payload`
        if [ "$actual_data" == "$expected_data" ]; then
          break
        fi

        sleep 1
      done

      fats_assert "$expected_data" "$actual_data"

      kubectl exec riff-dev -n $NAMESPACE -- sh -c 'kill $(pidof subscribe)'

      riff streaming stream delete ${lower_stream} --namespace $NAMESPACE
      riff streaming stream delete ${upper_stream} --namespace $NAMESPACE
      riff streaming processor delete ${processor} --namespace $NAMESPACE
    fi

    # cleanup
    riff function delete ${name} --namespace ${NAMESPACE}
    fats_delete_image ${image}

    echo "##[endgroup]"
  done

  # applications
#   for test in node java-boot; do
#     name=fats-${mode}-app-uppercase-${test}
#     image=$(fats_image_repo ${name})

#     echo "##[group]Run application ${name}"

#     if [ "${mode}" == "cluster" ]; then
#       riff application create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
#         --git-repo https://github.com/${FATS_REPO} --git-revision ${FATS_REFSPEC} --sub-path applications/uppercase/${test}
#     elif [ "${mode}" == "local" ]; then
#       riff application create ${name} --image ${image} --namespace ${NAMESPACE} --tail \
#         --local-path ${FATS_DIR}/applications/uppercase/${test}
#     else
#       echo "Unknown mode: ${mode}"
#       exit 1
#     fi

#     # core runtime
#     riff core deployer create ${name} --application-ref ${name} --namespace ${NAMESPACE} --tail
#     source ${FATS_DIR}/macros/invoke_core_deployer.sh ${name} "--get --data-urlencode input=fats" FATS
#     riff core deployer delete ${name} --namespace ${NAMESPACE}

#     # knative runtime
#     riff knative deployer create ${name} --application-ref ${name} --namespace ${NAMESPACE} --tail
#     source ${FATS_DIR}/macros/invoke_knative_deployer.sh ${name} "--get --data-urlencode input=fats" FATS
#     riff knative deployer delete ${name} --namespace ${NAMESPACE}

#     # cleanup
#     riff application delete ${name} --namespace ${NAMESPACE}
#     fats_delete_image ${image}

#     echo "##[endgroup]"
#   done
done

riff streaming kafka-provider delete franz --namespace $NAMESPACE
