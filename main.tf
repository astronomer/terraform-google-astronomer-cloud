# Deploy all the cloud-specific underlying infrastructure.
# Networks, Database, Kubernetes cluster, etc.
module "gcp" {
  source  = "astronomer/astronomer-gcp/google"
  version = "1.0.68"
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

  # don't create A record - we intend to do so manually.
  do_not_create_a_record = var.do_not_create_a_record

  # if the TLS cert and key are provided, we will want to use
  # them instead of asking for a Let's Encrypt cert.
  lets_encrypt = var.lets_encrypt
}

# Install tiller, which is the server-side component
# of Helm, the Kubernetes package manager.
# Install Istio service mesh via helm charts.
module "system_components" {
  dependencies = [module.gcp.depended_on]
  source       = "astronomer/astronomer-system-components/kubernetes"
  version      = "0.1.0"
  enable_istio = var.enable_istio
}

# Install the Astronomer platform via a helm chart
module "astronomer" {
  dependencies       = [module.system_components.depended_on]
  source             = "astronomer/astronomer/kubernetes"
  version            = "1.1.20"
  astronomer_version = "0.10.0-alpha.5"

  db_connection_string = module.gcp.db_connection_string
  tls_cert             = var.tls_cert == "" ? module.gcp.tls_cert : var.tls_cert
  tls_key              = var.tls_cert == "" ? module.gcp.tls_key : var.tls_key

  gcp_default_service_account_key = module.gcp.gcp_default_service_account_key

  astronomer_helm_values = local.astronomer_helm_values
}
