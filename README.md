# Deploy Astronomer Platform on a Google Environment

Requires Terraform 0.12+

[Terraform](https://www.terraform.io/) is a simple and powerful tool that lets us write, plan and create infrastructure as code. This code will allow you to efficiently provision the infrastructure required to run the Astronomer platform.

This repo uses the following Terraform modules:

| Module                                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------ |
| [astronomer/astronomer-gcp/google](https://registry.terraform.io/modules/astronomer/astronomer-gcp/)                                 |
| [astronomer/astronomer-system-components/kubernetes](https://registry.terraform.io/modules/astronomer/astronomer-system-components/) |
| [astronomer/astronomer/kubernetes](https://registry.terraform.io/modules/astronomer/astronomer/)                                     |

These modules are downloaded from Terraform Registry into a local `.terraform` directory.

## Steps

1. Set Google application default credentials:

   ```bash
   gcloud auth application-default login
   ```

1. Create Terraform Variables file (`terraform.tfvars`):

   A sample `terraform.tfvars.sample` file is provided in the repo.
   You can remove `.sample` from the filename and update the values based on your environment.

   Example:

   ```
   email            = "kaxil@astronomer.io"
   deployment_id    = "staging"
   dns_managed_zone = "steven-zone"
   management_api   = "public"
   ```

1. Copy `providers.tf.example` & rename it to `providers.tf` and replace `PROJECT` with your GCP Project ID:

   ```bash
   cp providers.tf.example providers.tf

   export PROJECT=GCP_PROJECT_ID
   sed -i "s/PROJECT/$PROJECT/g" providers.tf
   ```

1. (Optional) If you want to use remote Terraform state file, copy `backend.tf.example` & rename it to `backend.tf` & replace `BUCKET` & `REPLACE` with appropriate values.

   ```bash
   cp backend.tf.example backend.tf

   export DEPLOYMENT_ID=DEPLOYMENT_ID	# Set this value
   export STATE_BUCKET=STATE_BUCKET	# Set this value

   sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf
   sed -i "s/BUCKET/$STATE_BUCKET/g" backend.tf
   ```

1. Run the `deploy.sh` bash script:

   ```bash
   bash deploy.sh terraform.tfvars
   ```

   OR

   ```bash
   ./deploy.sh terraform.tfvars
   ```

   This bash script would run all the necessary Terraform steps.

## Destroy Deployment

1. Run the following command:

   ```bash
   ./destroy.sh terraform.tfvars
   ```
