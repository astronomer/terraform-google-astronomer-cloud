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

export EXAMPLE='from_scratch'

cp providers.tf.example examples/$EXAMPLE/providers.tf
cp backend.tf.example examples/$EXAMPLE/backend.tf

cd examples/$EXAMPLE
sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf
sed -i "s/BUCKET/astronomer-staging-terraform-state/g" backend.tf
sed -i "s/PROJECT/astronomer-cloud-staging/g" providers.tf

terraform init

# TODO: add to CI image
apk add jq

# copy the kubeconfig from the terraform state
terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig
chmod 755 kubeconfig

terraform apply --auto-approve \
  -var "deployment_id=$DEPLOYMENT_ID" \
  -var "dns_managed_zone=staging-zone" \
  -var "zonal=$ZONAL" \
  -var "kubeconfig_path=./kubeconfig" \
  -lock=false \
  -input=false

rm providers.tf
rm backend.tf
