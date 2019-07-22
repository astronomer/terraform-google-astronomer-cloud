#!/bin/bash

echo $GOOGLE_CREDENTIAL_FILE_CONTENT > /tmp/account.json

set -xe

ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'
export TF_IN_AUTOMATION=true

terraform -v

# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID='prod'
ZONAL='false'

export EXAMPLE='from_scratch'

cp providers.tf.example examples/$EXAMPLE/providers.tf
cp backend.tf.example examples/$EXAMPLE/backend.tf

cd examples/$EXAMPLE
# TODO: swap to prod stuff when we get a new project
sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf
sed -i "s/BUCKET/astronomer-staging-terraform-state/g" backend.tf
sed -i "s/PROJECT/astronomer-cloud-staging/g" providers.tf

terraform init

if [[ ${TF_PLAN:-0} -eq 1 ]]; then
	terraform plan -detailed-exitcode \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -out=tfplan \
	  -input=false
fi

if [[ ${TF_APPLY:-0} -eq 1 ]]; then

  # TODO: add to CI image
  apk add jq

  if [[ ${FORCE_APPLY:-0} -eq 1 ]]; then
    terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig || true
	  terraform apply --auto-approve \
	    -var "deployment_id=$DEPLOYMENT_ID" \
	    -var "dns_managed_zone=staging-zone" \
	    -var "zonal=$ZONAL" \
	    -lock=false \
	    -input=false
  fi

  terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig

	terraform apply --auto-approve \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -refresh=false \
	  -input=false $PLAN_FILE
fi

rm providers.tf
rm backend.tf
