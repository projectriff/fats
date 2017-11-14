# PFS System Test Codebase

To run this test, ensure a working PFS (`sk8s`) deployment exists in a k8s cluster.

Set up the following environment variables:

```
export SYS_TEST_CLI_PATH=<path-to-go-CLI>
export SYS_TEST_BASE_DIR=<path-to-test-dir-with-samples>
export SYS_TEST_NS=<k8s-ns-to-run-tests>
export SYS_TEST_KAFKA_POD_NAME=<pod-running-kafka>
export SYS_TEST_HTTP_GW_URL=http://http-gw-url:1234
export SYS_TEST_DOCKER_ORG=<docker-org>
export SYS_TEST_DOCKER_USERNAME=<docker-username>
export SYS_TEST_DOCKER_PASSWORD=<docker-password>
export SYS_TEST_MSG_RT_TIMEOUT_SEC=<message-timeout-seconds>
```

Invoke `test.sh`
