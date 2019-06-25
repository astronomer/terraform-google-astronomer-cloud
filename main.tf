module "gcp" {
  # source               = "astronomer/astronomer-gcp/google"
  # version              = "0.2.2"
  source               = "./terraform-google-astronomer-gcp"
  admin_emails         = [var.email]
  deployment_id        = var.deployment_id
  dns_managed_zone     = var.dns_managed_zone
  project              = var.project
}

module "system_components" {
  # source       = "astronomer/astronomer-system-components/kubernetes"
  # version      = "0.0.2"
  source       = "./terraform-kubernetes-astronomer-system-components"
  enable_istio = "true"
}

module "astronomer" {
  # you can do it like this for development
  # just comment out version, source
  # source = "./terraform-kubernetes-astronomer"
  source  = "astronomer/astronomer/kubernetes"
  version = "1.0.1"
  base_domain           = module.gcp.base_domain
  db_connection_string  = module.gcp.db_connection_string
  tls_cert              = module.gcp.tls_cert
  tls_key               = module.gcp.tls_key
  private_load_balancer = false
  # indicates which kind of LB to use for Nginx
  cluster_type          = "public"
  enable_istio          = "true"
  enable_gvisor         = "true"
}
