#!/bin/bash

gcloud_dir="${1:-google-cloud-sdk}"
mkdir -p $gcloud_dir

if ! [ -x "$(command -v gcloud)" ]; then
  if hash choco 2>/dev/null; then
    choco install gcloudsdk --ignore-checksums

    # expose gcloud to the path
    cat <<EOF > /usr/bin/gcloud
#!/bin/bash

"/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk/bin/gcloud" \$@
EOF

    # expose all gcloudsdk *.cmd into the path
    while read -r cmd; do
      cat <<EOF > /usr/bin/${cmd}
#!/bin/bash

"/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk/bin/${cmd}.cmd" \$@
EOF
    done <<< "$(ls -1 '/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk/bin/' | grep \.cmd | cut -d. -f1)"
  else
    # install a versioned archive
    curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-306.0.0-linux-x86_64.tar.gz | tar xz -C $gcloud_dir --strip-components 1
    ./$gcloud_dir/install.sh --quiet
    source $gcloud_dir/path.bash.inc
  fi
fi

gcloud config set project cf-spring-pfs-eng
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud config set disable_prompts True

echo $GCLOUD_CLIENT_SECRET | base64 --decode > key.json
gcloud auth activate-service-account --key-file key.json
rm key.json
