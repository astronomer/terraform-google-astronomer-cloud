#!/bin/bash

set -xe

if [ ! -f $1 ]; then
  echo "$1 is not a file, please provide a path to a variables file."
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# We still need to publish the top-level umbrella chart. Right now,
# are only publishing each subchart individually (chart - helm terminology)
if [ ! -d $DIR/helm.astronomer.io ]; then
  git clone https://github.com/astronomer/helm.astronomer.io.git
fi

terraform init

# deploy EKS, RDS
terraform apply -var-file=$1 --target=module.gcp

BASTION='staging-bastion'
ZONE=$(gcloud compute instances list --filter="name=('$BASTION')" --format 'csv[no-heading](zone)')

gcloud beta compute ssh --zone $ZONE $BASTION --tunnel-through-iap --ssh-flag='-L 1234:127.0.0.1:8888 -C -N' &
PROXY_PID=$!
# similar to 'finally' in Python
function finish {
  # Your cleanup code here
  kill $PROXY_PID
}
trap finish EXIT
sleep 5 # give the proxy time to establish

# install Tiller in the cluster
https_proxy=http://127.0.0.1:1234 terraform apply -var-file=$1 --target=module.system_components

# install astronomer in the cluster
https_proxy=http://127.0.0.1:1234 terraform apply -var-file=$1 --target=module.astronomer
