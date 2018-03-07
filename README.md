# FaaS Acceptance Test Suite (FATS) for riff [![Build Status](https://travis-ci.org/projectriff/fats.svg?branch=master)](https://travis-ci.org/projectriff/fats)

Uses travis-ci to run acceptance tests

Travis will:
- install and configure kubectl, docker, gcloud and helm
- create a GKE cluster
- install riff into GKE via helm
- deploy, invoke and delete functions for:
    - java
    - node
    - shell
    - python2 (pending support in riff)
- deletes GKE cluster

Attempts are made to cleanup all Google Cloud resources that are
created, however, if the script errors the resources may be stuck.

GKE clusters start with the prefix `ci-fats-`.
Docker image repositories start with `gcr.io/cf-spring-pfs-dev/fats-`.

The `pfs-ci@cf-spring-pfs-eng.iam.gserviceaccount.com` service account
is used to access Google Cloud. The authentication key-file is provided
as a base64 encoded secure env var named `GCLOUD_CLIENT_SECRET`. To
rotate the credentials, update the secure env var section of the
travis-ci settings with the value generated from
`cat [downloaded keyfile].json | base64 | pbcopy`.
