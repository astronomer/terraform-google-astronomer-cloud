module "gcp" {
  source           = "astronomer/astronomer-gcp/google"
  version          = "0.2.4"
  admin_emails     = [var.email]
  deployment_id    = var.deployment_id
  dns_managed_zone = var.dns_managed_zone
  project          = var.project
}

module "system_components" {
  source       = "astronomer/astronomer-system-components/kubernetes"
  version      = "0.0.3"
  enable_istio = "true"
}

module "astronomer" {
  source                = "astronomer/astronomer/kubernetes"
  version               = "1.0.2"
  base_domain           = module.gcp.base_domain
  db_connection_string  = module.gcp.db_connection_string
  tls_cert              = module.gcp.tls_cert
  tls_key               = module.gcp.tls_key
  private_load_balancer = false
  # indicates which kind of LB to use for Nginx
  cluster_type                    = "public"
  enable_istio                    = "true"
  enable_gvisor                   = "true"
  gcp_default_service_account_key = module.gcp.gcp_default_service_account_key
  container_registry_bucket_name  = module.gcp.container_registry_bucket_name
}
