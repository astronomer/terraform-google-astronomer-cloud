# Deploy Astronomer Platform on a Google Environment

Requires Terraform 0.12+

[Terraform](https://www.terraform.io/) is a simple and powerful tool that lets us write, plan and create infrastructure as code. This code will allow you to efficiently provision the infrastructure required to run the Astronomer platform.

This repo uses the following Terraform modules:

| Module                                                                                                                               | Version |
|--------------------------------------------------------------------------------------------------------------------------------------|---------|
| [astronomer/astronomer-gcp/google](https://registry.terraform.io/modules/astronomer/astronomer-gcp/)                                 | 0.2.4   |
| [astronomer/astronomer-system-components/kubernetes](https://registry.terraform.io/modules/astronomer/astronomer-system-components/) | 0.0.3   |
| [astronomer/astronomer/kubernetes](https://registry.terraform.io/modules/astronomer/astronomer/)                                     | 1.0.2   |

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
    project          = "astronomer-cloud-dev-236021"
    email            = "kaxil@astronomer.io"
    deployment_id    = "staging"
    dns_managed_zone = "steven-zone"
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
    export https_proxy=http://127.0.0.1:1234
    export no_proxy="googleapis.com,.google.com,metadata,.googleapis.com,github.com,.github.com"
    
    terraform destroy 
    # OR
    # terraform destroy -var-file=TFVAR_FILE_NAME
    
    unset no_proxy https_proxy
    ```
