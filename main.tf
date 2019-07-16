# Deploy all the cloud-specific underlying infrastructure.
# Networks, Database, Kubernetes cluster, etc.
module "gcp" {
  source  = "astronomer/astronomer-gcp/google"
  version = "1.0.32"
  # source              = "../terraform-google-astronomer-gcp"
  email               = var.email
  deployment_id       = var.deployment_id
  dns_managed_zone    = var.dns_managed_zone
  zonal_cluster       = var.zonal_cluster
  management_endpoint = var.management_api
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
  version            = "1.1.17"
  astronomer_version = "0.10.0-alpha.1"

  base_domain          = module.gcp.base_domain
  db_connection_string = module.gcp.db_connection_string
  tls_cert             = module.gcp.tls_cert
  tls_key              = module.gcp.tls_key
  load_balancer_ip     = module.gcp.load_balancer_ip

  cluster_type                    = "public"
  private_load_balancer           = false
  enable_istio                    = "true"
  enable_gvisor                   = "true"
  gcp_default_service_account_key = "${join("", [module.gcp.gcp_default_service_account_key])}"
  container_registry_bucket_name  = module.gcp.container_registry_bucket_name
}
