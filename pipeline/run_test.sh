#!/bin/bash

echo $GOOGLE_CREDENTIAL_FILE_CONTENT > /tmp/account.json

set -xe

ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'

terraform -v

# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID=ci$(echo "$DRONE_REPO_NAME$DRONE_BUILD_NUMBER" | md5sum | awk '{print substr($1,0,5)}')

curl -vvv https://app.${DEPLOYMENT_ID}.steven-google-development.com

curl -vvv https://houston.${DEPLOYMENT_ID}.steven-google-development.com/v1/healthz

echo "tests successful"
