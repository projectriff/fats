#!/bin/bash

gcloud_version=241.0.0

if hash choco 2>/dev/null; then
  gcloud_dir="/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk"
  mkdir -p "${gcloud_dir}"
  curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_version}-windows-x86.zip > gcloud.zip
  unzip -q -d "${gcloud_dir}" gcloud.zip && f=("${gcloud_dir}"/*) && mv "${gcloud_dir}"/*/* "${gcloud_dir}" && rm -rf "${f[@]}"
  rm gcloud.zip
else
  gcloud_dir="$HOME/google-cloud-sdk"
  mkdir -p "${gcloud_dir}"
  curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_version}-linux-x86_64.tar.gz  \
    | tar xz -C $gcloud_dir --strip-components=1
fi

# add to path
# this is a hack since we can't mutate the PATH inside this script and have it exposed to the caller and future scripts
for c in gcloud gsutil docker-credential-gcloud; do
  cat <<EOF | sudo tee -a /usr/local/bin/${c}
#!/bin/bash

"${gcloud_dir}/bin/${c}" \$@
EOF
  sudo chmod +x /usr/local/bin/${c}
done

gcloud config set project cf-spring-pfs-eng
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud config set disable_prompts True

echo $GCLOUD_CLIENT_SECRET | base64 --decode > key.json
gcloud auth activate-service-account --key-file key.json
rm key.json
gcloud auth configure-docker

unset gcloud_version
unset gcloud_dir
