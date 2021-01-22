#!/bin/bash

echo "${GOOGLE_CREDENTIAL_FILE_CONTENT}" > /tmp/account.json

set -xe

# shellcheck disable=SC2010
ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'

terraform -v

# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID=ci$(echo "$DRONE_REPO_NAME$DRONE_BUILD_NUMBER" | md5sum | awk '{print substr($1,0,5)}')
ZONAL='true'
PROJECT='astronomer-cloud-dev-236021'

if [ "$REGIONAL" -eq 1 ]; then
  DEPLOYMENT_ID="regional${DEPLOYMENT_ID}"
  ZONAL='false'
fi

echo "$DEPLOYMENT_ID"

cp providers.tf.example "examples/$EXAMPLE/providers.tf"
cp backend.tf.example "examples/$EXAMPLE/backend.tf"
cd "examples/$EXAMPLE"

sed -i "s/REPLACE/${DEPLOYMENT_ID}/g" backend.tf
sed -i "s/BUCKET/cloud2-dev-terraform/g" backend.tf
sed -i "s/PROJECT/${PROJECT}/g" providers.tf

cat providers.tf
cat backend.tf

terraform init

# TODO: add to CI image
apk add --update python curl which bash jq
curl -sSL https://sdk.cloud.google.com > /tmp/gcl
bash /tmp/gcl --install-dir=~/gcloud --disable-prompts > /dev/null 2>&1
PATH=$PATH:/root/gcloud/google-cloud-sdk/bin

# Set up gcloud CLI
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud config set project $PROJECT

if [ "$DESTROY" -eq 1 ]; then

    # don't error out if some of these fail
    set +e

    # whitelist our current IP for kube management API
    gcloud container clusters update "${DEPLOYMENT_ID}-cluster" --enable-master-authorized-networks --master-authorized-networks="$(curl -sS https://api.ipify.org)/32" --zone=us-east4-a

    # copy the kubeconfig from the terraform state
    terraform state pull | jq -r '.resources[] | select(.module == "module.astronomer_cloud") | select(.name == "kubeconfig") | .instances[0].attributes.content' > kubeconfig
    chmod 755 kubeconfig
    export KUBECONFIG="$PWD/kubeconfig"

    # delete everything from kube
    helm init --client-only
    helm ls --all --short | xargs -I{} helm del {} --purge
    kubectl delete namespace astronomer

    # remove the stuff we just delete from kube from the tf state
    terraform state rm module.astronomer_cloud.module.astronomer
    terraform state rm module.astronomer_cloud.module.system_components

    # this resource should be ignored on destroy
    # remove it from the state to accomplish this
    terraform state rm module.astronomer_cloud.module.gcp.google_sql_user.airflow

    # resume normal failure
    set -e

    terraform destroy --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false -refresh=false

else

    # create this first in order to fail fast if it does not work
    terraform apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false --target=module.astronomer_cloud.module.gcp.google_service_networking_connection.private_vpc_connection

    terraform apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false --target=module.astronomer_cloud.module.gcp
    terraform apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false -refresh=false
fi

rm providers.tf
rm backend.tf
