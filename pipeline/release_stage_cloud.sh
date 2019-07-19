#!/bin/bash

echo $GOOGLE_CREDENTIAL_FILE_CONTENT > /tmp/account.json

set -xe

ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'

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

terraform apply --auto-approve \
  -var "deployment_id=$DEPLOYMENT_ID" \
  -var "dns_managed_zone=staging-zone" \
  -var "zonal=$ZONAL" \
  -lock=false \
  --target=module.astronomer_cloud.module.gcp

terraform apply --auto-approve \
  -var "deployment_id=$DEPLOYMENT_ID" \
  -var "dns_managed_zone=staging-zone" \
  -var "zonal=$ZONAL" \
  -lock=false \
  -refresh=false \
  --target=module.astronomer_cloud.local_file.kubeconfig

terraform apply --auto-approve \
  -var "deployment_id=$DEPLOYMENT_ID" \
  -var "dns_managed_zone=staging-zone" \
  -var "zonal=$ZONAL" \
  -lock=false \
  -refresh=false
