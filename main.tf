# Deploy all the cloud-specific underlying infrastructure.
# Networks, Database, Kubernetes cluster, etc.
module "gcp" {
  source  = "astronomer/astronomer-gcp/google"
  version = "1.0.43"
  # source              = "../terraform-google-astronomer-gcp"
  email               = var.email
  deployment_id       = var.deployment_id
  dns_managed_zone    = var.dns_managed_zone
  zonal_cluster       = var.zonal_cluster
  management_endpoint = var.management_api
  # How long to wait after deploying GKE.
  # This is needed GKE-managed services to stabilize.
  wait_for = "430"
  # this setting is for how to configure the multi-tenant
  # node pool
  enable_gvisor = var.enable_gvisor
}

# Install tiller, which is the server-side component
# of Helm, the Kubernetes package manager.
# Install Istio service mesh via helm charts.
module "system_components" {
  dependencies = [module.gcp.depended_on]
  source       = "astronomer/astronomer-system-components/kubernetes"
  version      = "0.1.0"
  enable_istio = true
}

# Install the Astronomer platform via a helm chart
module "astronomer" {
  dependencies       = [module.system_components.depended_on]
  source             = "astronomer/astronomer/kubernetes"
  version            = "1.1.18"
  astronomer_version = "0.10.0-alpha.4"

  db_connection_string = module.gcp.db_connection_string
  tls_cert             = module.gcp.tls_cert
  tls_key              = module.gcp.tls_key

  gcp_default_service_account_key = module.gcp.gcp_default_service_account_key

  astronomer_helm_values = local.astronomer_helm_values
}
