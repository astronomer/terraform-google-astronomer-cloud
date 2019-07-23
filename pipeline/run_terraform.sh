#!/bin/bash

echo $GOOGLE_CREDENTIAL_FILE_CONTENT > /tmp/account.json

set -xe

ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'

terraform -v

# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID=ci$(echo "$DRONE_REPO_NAME$DRONE_BUILD_NUMBER" | md5sum | awk '{print substr($1,0,5)}')
ZONAL='true'

if [ $REGIONAL -eq 1 ]; then
  DEPLOYMENT_ID=regional$DEPLOYMENT_ID
  ZONAL='false'
fi

echo $DEPLOYMENT_ID

cp providers.tf.example examples/$EXAMPLE/providers.tf
cp backend.tf.example examples/$EXAMPLE/backend.tf
cd examples/$EXAMPLE

sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf
sed -i "s/BUCKET/cloud2-dev-terraform/g" backend.tf
sed -i "s/PROJECT/astronomer-cloud-dev-236021/g" providers.tf

cat providers.tf
cat backend.tf

terraform init

if [ $DESTROY -eq 1 ]; then
    # this resource should be ignored on destroy
    # remove it from the state to accomplish this
    terraform state rm module.astronomer_cloud.module.gcp.google_sql_user.airflow

    # this stuff helps the delete be a little more reliable, since
    # we don't rely on the kube api.
    terraform state rm module.astronomer_cloud.module.astronomer
    terraform state rm module.astronomer_cloud.module.system_components

    terraform destroy --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false -refresh=false
else
    terraform apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false --target=module.astronomer_cloud.module.gcp
    terraform apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -var "dns_managed_zone=steven-zone" -lock=false -refresh=false
fi

rm providers.tf
rm backend.tf
