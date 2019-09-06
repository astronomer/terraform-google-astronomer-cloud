#!/bin/sh

apk add sed

cd /tmp
eval `ssh-agent`
echo "$DEPLOY_KEY" | ssh-add -
mkdir -p $HOME/.ssh

set -xe
ssh-keyscan -t rsa github.com >> $HOME/.ssh/known_hosts
git clone git@github.com:astronomer/google-environments.git
cd google-environments
sed -i "s/version\s=\s\"[0-9]*\.[0-9]*\.[0-9]*\"/version = \"$DRONE_TAG\"/g" stage/cloud/main.tf
sed -i "s/version\s=\s\"[0-9]*\.[0-9]*\.[0-9]*\"/version = \"$DRONE_TAG\"/g" prod/cloud/main.tf
git add stage/cloud/main.tf
git add prod/cloud/main.tf
git status
git config --global user.email "steven@astronomer.io"
git config --global user.name "Drone CI"
git commit -m "Drone CI: Update cloud configuration with Terraform cloud module version $DRONE_TAG"
git push origin master
