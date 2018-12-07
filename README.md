# FaaS Acceptance Test Suite (FATS) for riff

FATS is a suite of scripts that support testing riff against various Kubernetes clusters.

## Running FATS

FATS is expected to be driven by the repository being tested.

An example config is provided in the `.travis.yml` file for this repo that doubles as a test suite for FATS itself. The configuration defines environment variables and scripts to invoke.

- `CLUSTER_NAME` a short, url safe, unique name (e.g. fats-123-4) used to distinguish resource between concurrent runs.
- `NAMESPACE` the namespace to install resources into. May be hard coded for clusters that are provisioned on demand or dynamic for clusters that are reused between runs. (Note: if resources are shared jobs should not run concurrently)
- `CLUSTER` the type of cluster to use. Some clusters will require additional environment variables
- `REGISTRY` the type of registry to use. Some registries will require addition environment variables

There are two scripts that are commonly defined for Travis based builds, other CI environments may be configured differently.

- `script` - starts the cluster then runs your tests. Run `./start.sh` to start the cluster and registry.
- `after_script` - runs after the script passes or fails. Run `./cleanup.sh` to cleanup the cluster and registry.

FATS will:

- configure and start a kubernetes cluster defined by `$CLUSTER`
- configure and start an image registry defined by `$REGISTRY`
- create, invoke (asserting correct output) and cleanup functions
- cleanup the cluster and registry after tests are complete

You need to:

- pick the cluster (set as $CLUSTER, e.g. 'minikube') and registry (set as $REGISTRY, e.g. 'dockerhub') to use, suppling any custom config they require.
- start FATS, typically:
  - `source ./start.sh`
- install and configure riff, typically:
  - `riff system install $SYSTEM_INSTALL_FLAGS` (SYSTEM_INSTALL_FLAGS is provided by FATS)
- create and configure the target namespace, typically:
  - `kubectl create namespace $NAMESPACE`
  - `fats_create_push_credentials $NAMESPACE`
  - `riff namespace init $NAMESPACE $NAMESPACE_INIT_FLAGS` (NAMESPACE_INIT_FLAGS is provided by FATS)
- specify functions to test, typically:
  - `source ./functions/helpers.sh`
  - per function `run_function <path-to-function> <name> <image> <input_data> <expected_output>` (name and image often include the CLUSTER_NAME for uniqueness)
- cleanup riff, typically:
  - `riff system uninstall --istio --force`
  - `kubectl delete namespace $NAMESPACE`
- cleanup FATS, typically:
  - `source ./cleanup.sh`


## Extending FATS

There are four extension points for FATS:

- clusters: kubernetes clusters
- registries: image registies where built functions are pushed before they are pulled into the cluster
- functions: sample functions that can be invoked with helper scripts to aid creating, invoking and cleaning up
- tools: items that need to be installed, like kubectl or gcloud

### Clusters

Support is provided for:

- gke
- minikube
- pks-gcp

To add a new cluster, create a directory under `./clusters/` and add three files:

- `configure.sh` - configuration shared by the start and cleanup scripts
  - set `SYSTEM_INSTALL_FLAGS` env var that is passed to `riff system install`
  - define function `wait_for_ingress_ready` that blocks until the cluster ingress is fully available
  - do any other one time configuration for the cluster
- `start.sh` - start the kubernetes cluster and set it as the default kubectl context
- `cleanup.sh` - shutdown the running cluster and clean up any shared or external resources

### Registries

Support is provided for:

- dockerhub
- gcr
- minikube (local registry via minikube addon)

To add a new registry, create a directory under `./registries/` and add three files:

- `configure.sh` - configuration for the registry
  - set `IMAGE_REPOSITORY_PREFIX` env var that includes repository host and user information that can be pushed to
  - set `NAMESPACE_INIT_FLAGS` env var that is passed to `riff namespace init`
  - define function `fats_delete_image` that deletes a published image
  - define function `fats_create_push_credentials` that creates a secret to be used to push incluster builds to the registry
  - do any other one time configuration for the registry (run before the cluster is started)
- `start.sh` - start the registry and set it as the default for docker push (run after the cluster is started)
- `cleanup.sh` - shutdown the running registry and clean up any shared or external resources

### Functions

Support is provided for:

- uppercase
  - command
  - java
  - java-boot
  - java-local
  - node
  - npm

To add a new function, create a directory anywhere, adding the following files:

- `.fats`
  - `create` - CLI arguments to pass to `riff function create`, typically `--git-repo <git-url>` or `--local-path .`, plus other function specific args like `--artifact` or `--handler`
- any other files for your function if using `--local-path .`

### Tools

Support is provided for:

- aws
- glcoud
- kail
- kubectl
- minikube
- pivnet
- pks

To add a new tool, create a file under `./tools/` as `<toolname>.sh`. Add any logic needed to install and configure the tool.
