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

if [[ ${TF_PLAN_MODULE_GCP:-0} -eq 1 ]]; then
	terraform plan -detailed-exitcode \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -target=module.astronomer_cloud.module.gcp \
	  -out=tfplan_module_gcp \
	  -input=false
fi

if [[ ${TF_APPLY_MODULE_GCP:-0} -eq 1 ]]; then
	terraform apply --auto-approve \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -target=module.astronomer_cloud.module.gcp \
	  -input=false tfplan_module_gcp
fi

if [[ ${TF_PLAN_TARGET_KUBECONFIG:-0} -eq 1 ]]; then
	terraform plan -detailed-exitcode \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -target=module.astronomer_cloud.local_file.kubeconfig \
	  -out=tfplan_target_kubeconfig \
	  -input=false
fi


if [[ ${TF_APPLY_TARGET_KUBECONFIG:-0} -eq 1 ]]; then
	terraform apply --auto-approve \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -refresh=false \
	  -target=module.astronomer_cloud.local_file.kubeconfig \
	  -input=false tfplan_target_kubeconfig
fi

if [[ ${TF_PLAN_FINAL:-0} -eq 1 ]]; then
	terraform plan -detailed-exitcode \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -out=tfplan_final \
	  -input=false
fi

if [[ ${TF_APPLY_FINAL:-0} -eq 1 ]]; then
	terraform apply --auto-approve \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
	  -lock=false \
	  -refresh=false \
	  -input=false tfplan_final
fi

rm providers.tf
rm backend.tf
