#!/bin/bash

echo $GOOGLE_CREDENTIAL_FILE_CONTENT > /tmp/account.json

set -xe

ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'
export TF_IN_AUTOMATION=true

terraform -v

# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID='staging'
ZONAL='false'
PROJECT='astronomer-cloud-staging'

export EXAMPLE='from_scratch'

cp providers.tf.example examples/$EXAMPLE/providers.tf
cp backend.tf.example examples/$EXAMPLE/backend.tf

cd examples/$EXAMPLE
sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf
sed -i "s/BUCKET/astronomer-staging-terraform-state/g" backend.tf
sed -i "s/PROJECT/$PROJECT/g" providers.tf

terraform init

# TODO: add to CI image
apk add --update  python  curl  which  bash jq
curl -sSL https://sdk.cloud.google.com > /tmp/gcl
bash /tmp/gcl --install-dir=~/gcloud --disable-prompts > /dev/null 2>&1
PATH=$PATH:/root/gcloud/google-cloud-sdk/bin

# Set up gcloud CLI
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud config set project $PROJECT

# copy the kubeconfig from the terraform state
terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig
chmod 755 kubeconfig

# whitelist our current IP for kube management API
gcloud container clusters update $DEPLOYMENT_ID-cluster --master-authorized-networks="$(curl icanhazip.com)/32" --zone=us-east4

terraform apply --auto-approve \
  -var "deployment_id=$DEPLOYMENT_ID" \
  -var "dns_managed_zone=staging-zone" \
  -var "zonal=$ZONAL" \
  -var "kubeconfig_path=$(pwd)/kubeconfig" \
  -lock=false \
  -input=false

rm providers.tf
rm backend.tf
