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
PROJECT='astronomer-cloud-staging'
STATE_BUCKET=astronomer-staging-terraform-state

export EXAMPLE='from_scratch'

cp providers.tf.example examples/$EXAMPLE/providers.tf
cp backend.tf.example examples/$EXAMPLE/backend.tf

cd examples/$EXAMPLE
# TODO: swap to prod stuff when we get a new project
sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf
sed -i "s/BUCKET/$STATE_BUCKET/g" backend.tf
sed -i "s/PROJECT/$PROJECT/g" providers.tf

terraform init

# TODO: add to CI image
apk add --update python curl which bash jq
curl -sSL https://sdk.cloud.google.com > /tmp/gcl
bash /tmp/gcl --install-dir=~/gcloud --disable-prompts > /dev/null 2>&1
PATH=$PATH:/root/gcloud/google-cloud-sdk/bin

# Set up gcloud CLI
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud config set project $PROJECT

if [[ ${FIRST_RUN:-0} -eq 1 ]]; then

# on astronomer-terraform-kubernetes-astronomer/secrets.tf line 34, in resource "kubernetes_secret" "astronomer-gcs-keyfile":
# 34: count = var.gcp_default_service_account_key != "" ? 1 : 0
# The "count" value depends on resource attributes that cannot be determined
# until apply, so Terraform cannot predict how many instances will be created.
# To work around this, use the -target argument to first apply only the
# resources that the count depends on.

  terraform apply --auto-approve \
    -var "deployment_id=$DEPLOYMENT_ID" \
    -var "dns_managed_zone=staging-zone" \
    -var "zonal=$ZONAL" \
    -lock=false \
    -input=false \
    --target=module.astronomer_cloud.module.gcp

  terraform apply --auto-approve \
    -var "deployment_id=$DEPLOYMENT_ID" \
    -var "dns_managed_zone=staging-zone" \
    -var "zonal=$ZONAL" \
    -lock=false \
    -refresh=false \
    -input=false

  exit 0

fi

# whitelist our current IP for kube management API
gcloud container clusters update $DEPLOYMENT_ID-cluster --enable-master-authorized-networks --master-authorized-networks="$(curl icanhazip.com)/32" --zone=us-east4

# have terraform clone the helm chart
terraform state rm module.astronomer_cloud.module.astronomer.null_resource.helm_repo

# copy the kubeconfig from the terraform state
terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig
chmod 755 kubeconfig

ls -ltra

if [[ ${TF_PLAN:-0} -eq 1 ]]; then

	echo "\n Deleting old Terraform plan file"
	gsutil rm gs://${STATE_BUCKET}/ci/tfplan || echo "\n State File does not exist"

	terraform plan \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
      -var "kubeconfig_path=$(pwd)/kubeconfig" \
	  -lock=false \
	  -out=tfplan \
	  -input=false

	gsutil cp tfplan gs://${STATE_BUCKET}/ci/tfplan

fi

if [[ ${TF_APPLY:-0} -eq 1 ]]; then

	echo "\n Retrieving Terraform plan from the GCS Bucket: ${STATE_BUCKET}"
	gsutil cp gs://${STATE_BUCKET}/ci/tfplan tfplan

	terraform apply --auto-approve \
	  -lock=false \
	  -refresh=false \
	  -input=false tfplan

fi

rm providers.tf
rm backend.tf