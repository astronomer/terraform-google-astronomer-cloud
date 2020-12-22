# Deploy all the cloud-specific underlying infrastructure.
# Networks, Database, Kubernetes cluster, etc.
module "gcp" {

  source = "github.com/astronomer/terraform-google-astronomer-gcp?ref=1.1.1"

  email                   = var.email
  deployment_id           = var.deployment_id
  dns_managed_zone        = var.dns_managed_zone
  zonal_cluster           = var.zonal_cluster
  management_endpoint     = var.management_api
  kube_api_whitelist_cidr = var.kube_api_whitelist_cidr

  enable_spotinist = var.enable_spotinist

  pod_security_policy_enabled = var.pod_security_policy_enabled

  # Enables GKE Metered Billing and exports billing data to BigQuery
  enable_gke_metered_billing = var.enable_gke_metered_billing

  # How long to wait after deploying GKE.
  # This is needed GKE-managed services to stabilize.
  wait_for = "430"

  # Kube version minimum
  kube_version_gke = var.kube_version_gke

  # GKE Release channel
  gke_release_channel = var.gke_release_channel

  # don't create A record - we intend to do so manually.
  do_not_create_a_record = var.do_not_create_a_record

  # if the TLS cert and key are provided, we will want to use
  # them instead of asking for a Let's Encrypt cert.
  lets_encrypt = var.lets_encrypt

  cloud_sql_tier     = var.db_instance_size
  db_max_connections = 2000

  # Enable KEDA
  webhook_ports = ["6443"]

  ## Node Pool configurations
  enable_blue_platform_node_pool       = var.enable_blue_platform_node_pool
  blue_platform_np_initial_node_count  = var.blue_platform_np_initial_node_count
  machine_type_platform_blue           = var.machine_type_platform_blue
  disk_size_platform_blue              = var.disk_size_platform_blue
  max_node_count_platform_blue         = var.max_node_count_platform_blue
  platform_node_pool_taints_blue       = var.platform_node_pool_taints_blue
  enable_green_platform_node_pool      = var.enable_green_platform_node_pool
  green_platform_np_initial_node_count = var.green_platform_np_initial_node_count
  machine_type_platform_green          = var.machine_type_platform_green
  disk_size_platform_green             = var.disk_size_platform_green
  max_node_count_platform_green        = var.max_node_count_platform_green
  platform_node_pool_taints_green      = var.platform_node_pool_taints_green
  enable_blue_mt_node_pool             = var.enable_blue_mt_node_pool
  blue_mt_np_initial_node_count        = var.blue_mt_np_initial_node_count
  machine_type_multi_tenant_blue       = var.machine_type_multi_tenant_blue
  disk_size_multi_tenant_blue          = var.disk_size_multi_tenant_blue
  max_node_count_multi_tenant_blue     = var.max_node_count_multi_tenant_blue
  mt_node_pool_taints_blue             = var.mt_node_pool_taints_blue
  enable_gvisor_blue                   = var.enable_gvisor_blue
  enable_green_mt_node_pool            = var.enable_green_mt_node_pool
  green_mt_np_initial_node_count       = var.green_mt_np_initial_node_count
  machine_type_multi_tenant_green      = var.machine_type_multi_tenant_green
  disk_size_multi_tenant_green         = var.disk_size_multi_tenant_green
  max_node_count_multi_tenant_green    = var.max_node_count_multi_tenant_green
  mt_node_pool_taints_green            = var.mt_node_pool_taints_green
  enable_gvisor_green                  = var.enable_gvisor_green
  create_dynamic_pods_nodepool         = var.create_dynamic_pods_nodepool
  dynamic_np_initial_node_count        = var.dynamic_np_initial_node_count
  disk_size_dynamic                    = var.disk_size_dynamic
  dynamic_node_pool_taints             = var.dynamic_node_pool_taints
  max_node_count_dynamic               = var.max_node_count_dynamic
  enable_gvisor_dynamic                = var.enable_gvisor_dynamic
  machine_type_dynamic                 = var.machine_type_dynamic
  enable_dynamic_blue_node_pool        = var.enable_dynamic_blue_node_pool
  dynamic_blue_np_initial_node_count   = var.dynamic_blue_np_initial_node_count
  machine_type_dynamic_blue            = var.machine_type_dynamic_blue
  disk_size_dynamic_blue               = var.disk_size_dynamic_blue
  disk_type_dynamic_blue               = var.disk_type_dynamic_blue
  max_node_count_dynamic_blue          = var.max_node_count_dynamic_blue
  dynamic_blue_node_pool_taints        = var.dynamic_blue_node_pool_taints
  enable_gvisor_dynamic_blue           = var.enable_gvisor_dynamic_blue
  enable_dynamic_green_node_pool       = var.enable_dynamic_green_node_pool
  dynamic_green_np_initial_node_count  = var.dynamic_green_np_initial_node_count
  machine_type_dynamic_green           = var.machine_type_dynamic_green
  disk_size_dynamic_green              = var.disk_size_dynamic_green
  disk_type_dynamic_green              = var.disk_type_dynamic_green
  max_node_count_dynamic_green         = var.max_node_count_dynamic_green
  dynamic_green_node_pool_taints       = var.dynamic_green_node_pool_taints
  enable_gvisor_dynamic_green          = var.enable_gvisor_dynamic_green
}

# Install tiller, which is the server-side component
# of Helm, the Kubernetes package manager.
# Install Istio service mesh via helm charts.
module "system_components" {
  dependencies = [module.gcp.depended_on]

  source = "github.com/astronomer/terraform-kubernetes-astronomer-system-components"

  astronomer_namespace               = var.astronomer_namespace
  enable_cloud_sql_proxy             = var.enable_cloud_sql_proxy
  enable_istio                       = var.enable_istio
  enable_knative                     = var.enable_knative
  enable_kubecost                    = var.enable_kubecost
  kubecost_token                     = var.kubecost_token
  gcp_service_account_key_json       = module.gcp.gcp_cloud_sql_admin_key
  cloudsql_instance                  = module.gcp.db_instance_name
  gcp_region                         = module.gcp.gcp_region
  gcp_project                        = module.gcp.gcp_project
  extra_istio_helm_values            = local.extra_istio_helm_values
  extra_googlesqlproxy_helm_values   = local.extra_googlesqlproxy_helm_values
  cloud_sql_proxy_helm_chart_version = "0.19.6"
  istio_helm_release_version         = "1.4.3"
  kubecost_helm_chart_version        = "1.45.1"
  tiller_version                     = var.tiller_version
  enable_velero                      = var.enable_velero
  extra_velero_helm_values           = local.extra_velero_helm_values
  extra_kubecost_helm_values         = local.extra_kubecost_helm_values
  tiller_tolerations                 = local.tiller_tolerations
  tiller_node_selectors              = local.tiller_node_selectors
}

# Install the Astronomer platform via a helm chart
module "astronomer" {
  dependencies = [module.system_components.depended_on, module.gcp.depended_on]

  source = "github.com/astronomer/terraform-kubernetes-astronomer?ref=gke-channels"

  astronomer_namespace            = var.astronomer_namespace
  install_astronomer_helm_chart   = var.install_astronomer_helm_chart
  astronomer_version              = var.astronomer_version
  astronomer_version_git_checkout = var.astronomer_version_git_checkout
  astronomer_chart_git_repository = var.astronomer_chart_git_repository
  astronomer_helm_chart_name      = var.astronomer_helm_chart_name
  wait_for_helm_chart             = var.wait_for_helm_chart
  astronomer_helm_chart_repo      = var.astronomer_helm_chart_repo
  astronomer_helm_chart_repo_url  = var.astronomer_helm_chart_repo_url

  db_connection_string = "postgres://${module.gcp.db_connection_user}:${module.gcp.db_connection_password}@pg-sqlproxy-gcloud-sqlproxy.${var.astronomer_namespace}:5432"
  # If var.tls_cert is an empty string then the result is "var.tls_cert",
  # but otherwise it is the actual value of var.tls_cert.
  tls_cert = var.tls_cert == "" ? module.gcp.tls_cert : var.tls_cert
  tls_key  = var.tls_key == "" ? module.gcp.tls_key : var.tls_key

  gcp_default_service_account_key = module.gcp.gcp_default_service_account_key

  astronomer_helm_values = local.astronomer_helm_values
}
