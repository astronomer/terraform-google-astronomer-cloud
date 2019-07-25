#!/bin/bash

cd /tmp
eval `ssh-agent`
echo "$DEPLOY_KEY" | ssh-add -
mkdir -p $HOME/.ssh
ssh-keyscan -t rsa github.com >> $HOME/.ssh/known_hosts
git clone git@github.com:astronomer/google-environments.git
cd google-environments
sed -i "s/version\s=\s\"[0-9]*\.[0-9]*\.[0-9]*\"/version = \"$DRONE_TAG\"/g" stage/cloud/main.tf
git commit -m "Drone CI: Update stage cloud with Astronomer chart version $DRONE_TAG"
git push origin master
