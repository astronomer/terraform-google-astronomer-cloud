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

if [[ ${FIRST_RUN:-0} -eq 1 ]]; then

  terraform apply --auto-approve \
    -var "deployment_id=$DEPLOYMENT_ID" \
    -var "dns_managed_zone=staging-zone" \
    -var "zonal=$ZONAL" \
    -lock=false \
    -input=false

  exit 0

fi

# TODO: add to CI image
apk add --update  python  curl  which  bash jq
curl -sSL https://sdk.cloud.google.com > /tmp/gcl && bash /tmp/gcl --install-dir=~/gcloud --disable-prompts
PATH=$PATH:/root/gcloud/google-cloud-sdk/bin

# Set up gcloud CLI
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud config set project $PROJECT

terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig
chmod 755 kubeconfig
gcloud container clusters update steven-cluster --master-authorized-networks="$(curl icanhazip.com)/32" --enable-master-authorized-networks --zone=us-east4

if [[ ${TF_PLAN:-0} -eq 1 ]]; then
	terraform plan -detailed-exitcode \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
    -var "kubeconfig_path=./kubeconfig" \
	  -lock=false \
	  -out=tfplan \
	  -input=false
fi

if [[ ${TF_APPLY:-0} -eq 1 ]]; then

	terraform apply --auto-approve \
	  -var "deployment_id=$DEPLOYMENT_ID" \
	  -var "dns_managed_zone=staging-zone" \
	  -var "zonal=$ZONAL" \
    -var "kubeconfig_path=./kubeconfig" \
	  -lock=false \
	  -refresh=false \
	  -input=false tfplan

fi

rm providers.tf
rm backend.tf
