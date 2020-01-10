# Deploy all the cloud-specific underlying infrastructure.
# Networks, Database, Kubernetes cluster, etc.
module "gcp" {
  source = "astronomer/astronomer-gcp/google"
  //  source              = "../terraform-google-astronomer-gcp"
  version             = "1.0.221"
  email               = var.email
  deployment_id       = var.deployment_id
  dns_managed_zone    = var.dns_managed_zone
  zonal_cluster       = var.zonal_cluster
  management_endpoint = var.management_api

  # Enables GKE Metered Billing and exports billing data to BigQuery
  enable_gke_metered_billing = var.enable_gke_metered_billing

  # How long to wait after deploying GKE.
  # This is needed GKE-managed services to stabilize.
  wait_for = "430"
  # this setting is for how to configure the multi-tenant
  # node pool
  enable_gvisor = var.enable_gvisor

  # Kube version minimum
  kube_version_gke = var.kube_version_gke

  # don't create A record - we intend to do so manually.
  do_not_create_a_record = var.do_not_create_a_record

  # if the TLS cert and key are provided, we will want to use
  # them instead of asking for a Let's Encrypt cert.
  lets_encrypt = var.lets_encrypt

  # Instance sizes
  machine_type          = var.worker_node_size
  machine_type_platform = "n1-standard-16"
  max_node_count        = var.max_worker_node_count
  cloud_sql_tier        = var.db_instance_size
  db_max_connections    = 1000

  # Only allow platform pods to created on this NodePool by using the below taint
  # Unless pods has the matching key,value for the taint the pods would not be
  # scheduled
  platform_node_pool_taints = [
    {
      effect = "NO_SCHEDULE"
      key    = "platform"
      value  = "true"
    },
  ]

  # This pool will be used to direct all dynamic KubernetesExecutor and
  # KubernetesPodOperator pods
  create_dynamic_pods_nodepool = var.create_dynamic_pods_nodepool
  dp_node_pool_taints = [
    {
      effect = "NO_SCHEDULE"
      key    = "dynamic-pods"
      value  = "true"
    },
  ]
}

# Install tiller, which is the server-side component
# of Helm, the Kubernetes package manager.
# Install Istio service mesh via helm charts.
module "system_components" {
  dependencies = [module.gcp.depended_on]
  source       = "astronomer/astronomer-system-components/kubernetes"
  version      = "0.1.18"
  //  source                       = "../terraform-kubernetes-astronomer-system-components"
  enable_cloud_sql_proxy             = true
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
  cloud_sql_proxy_helm_chart_version = "0.19.2"
  istio_helm_release_version         = "1.3.0"
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
  dependencies       = [module.system_components.depended_on, module.gcp.depended_on]
  source             = "astronomer/astronomer/kubernetes"
  version            = "1.1.55"
  astronomer_version = "0.11.0-rc.4"

  db_connection_string = "postgres://${module.gcp.db_connection_user}:${module.gcp.db_connection_password}@pg-sqlproxy-gcloud-sqlproxy.astronomer:5432"
  tls_cert             = var.tls_cert == "" ? module.gcp.tls_cert : var.tls_cert
  tls_key              = var.tls_key == "" ? module.gcp.tls_key : var.tls_key

  gcp_default_service_account_key = module.gcp.gcp_default_service_account_key

  astronomer_helm_values = local.astronomer_helm_values
}
