variable "base_domain" {
  default     = ""
  type        = string
  description = "if blank, will use from gcp module"
}

variable "db_instance_size" {
  default = "db-f1-micro"
  type    = string
}

variable "stripe_secret_key" {
  default = ""
  type    = string
}

variable "stripe_pk" {
  default = ""
  type    = string
}

variable "pagerduty_service_key" {
  default = ""
  type    = string
}

variable "slack_alert_channel_platform" {
  default = ""
  type    = string
}

variable "slack_alert_url_platform" {
  default = ""
  type    = string
}

variable "slack_alert_channel" {
  default = ""
  type    = string
}

variable "slack_alert_url" {
  default = ""
  type    = string
}

variable "dns_managed_zone" {
  default = ""
  type    = string
}

variable "email" {
  type = string
}

variable "deployment_id" {
  type = string
}

variable "public_signups" {
  default = true
  type    = bool
}

variable "enable_istio" {
  default = true
  type    = bool
}

variable "enable_kubecost" {
  default = false
  type    = bool
}

variable "kubecost_token" {
  default = ""
  type    = string
}

variable "zonal_cluster" {
  default = false
  type    = bool
}

variable "management_api" {
  default = "private"
  type    = string
}

variable "smtp_uri" {
  default = ""
  type    = string
}

variable "kubeconfig_path" {
  default = ""
  type    = string
}

variable "do_not_create_a_record" {
  default = false
  type    = bool
}

variable "tls_cert" {
  default     = ""
  type        = string
  description = "The signed certificate for the Astronomer Load Balancer. It should be signed by a certificate authorize and should have common name *.base_domain. Ignored if var.lets_encrypt is true."
}

variable "tls_key" {
  default     = ""
  type        = string
  description = "The private key corresponding to the signed certificate tls_cert. Ignored if var.lets_encrypt is true"
}

variable "lets_encrypt" {
  default = true
  type    = bool
}

variable "enable_velero" {
  default = true
  type    = bool
}

# https://cloud.google.com/kubernetes-engine/docs/release-notes-regular
variable "kube_version_gke" {
  default     = "1.17.13-gke.2001"
  description = "The kubernetes version to use in GKE"
}

variable "gke_release_channel" {
  default     = "REGULAR"
  type        = string
  description = "The GKE Release channel to use. Blank for none"
}

variable "tiller_version" {
  default     = "2.16.1"
  description = "The version of tiller to install"
}

variable "enable_knative" {
  type        = bool
  default     = false
  description = "enable_istio=true is required for knative to work"
}

variable "enable_gke_metered_billing" {
  type        = bool
  default     = true
  description = "If true, enables GKE metered billing to track costs on namespaces & label level"
}

variable "astronomer_helm_values" {
  type        = string
  description = "The Helm values to apply to the Astronomer platform"
}

variable "astronomer_version_git_checkout" {
  description = "Verison of the helm chart to use, when using git clone method. This should exactly match what you would want to use with 'git checkout <this variable>'. This is ignored if astronomer_chart_git_repository is not configured."
  default     = "v0.11.0-astro.8"
  type        = string
}

variable "astronomer_chart_git_repository" {
  description = "Git repository clone url, when using git clone method. This should exactly match what you would want to use with 'git clone <this variable>'. It is better to not use this and instead use just the astronomer_version variable, which will pull from the Astronomer Helm chart repository."
  default     = ""
  type        = string
}

variable "astronomer_version" {
  description = "Verison of Helm chart to use, do not include a 'v' at the front"
  default     = "0.12.0-alpha.1"
  type        = string
}

variable "astronomer_helm_chart_name" {
  description = "The name of the Astronomer Helm chart to install from the Astronomer Helm chart repository."
  default     = "astronomer"
  type        = string
}

variable "wait_for_helm_chart" {
  description = "Should we wait for Astronomer to come up before indicating the apply is complete?"
  default     = true
  type        = bool
}

variable "astronomer_helm_chart_repo" {
  description = "The name of the Astronomer Helm chart repo"
  default     = "astronomer"
  type        = string
}

variable "astronomer_helm_chart_repo_url" {
  description = "The url of the Astronomer Helm chart repo"
  default     = "https://helm.astronomer.io"
  type        = string
}

### Node Pool settings
# Blue / Green node pools feature is to allow Terraform users
# careful control of node pool changes

## Platform node pool: Blue

variable "enable_blue_platform_node_pool" {
  type        = bool
  default     = true
  description = "Turn on the blue platform node pool"
}

variable "blue_platform_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the blue platform node pool"
}

variable "machine_type_platform_blue" {
  default     = "n1-standard-16"
  type        = string
  description = "The GCP machine type for GKE worker nodes running platform components"
}

variable "disk_size_platform_blue" {
  default     = 200
  type        = number
  description = "Number of GB available on Nodes' local disks for the platform node pool, which runs Astronomer components"
}

variable "max_node_count_platform_blue" {
  default     = 10
  type        = number
  description = "The approximate maximum number of nodes in the platform node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "platform_node_pool_taints_blue" {
  description = "Taints to apply to the platform node pool "
  type        = list(any)
  default = [{
    effect = "NO_SCHEDULE"
    key    = "platform"
    value  = "true"
  }, ]
}

## Platform node pool: Green

variable "enable_green_platform_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green platform node pool"
}

variable "green_platform_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the green platform node pool"
}

variable "machine_type_platform_green" {
  default     = "n1-standard-16"
  type        = string
  description = "The GCP machine type for GKE worker nodes running platform components"
}

variable "disk_size_platform_green" {
  default     = 200
  type        = number
  description = "Number of GB available on Nodes' local disks for the platform node pool, which runs Astronomer components"

}

variable "max_node_count_platform_green" {
  default     = 10
  type        = number
  description = "The approximate maximum number of nodes in the platfor node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "platform_node_pool_taints_green" {
  description = "Taints to apply to the Platform Node Pool "
  type        = list(any)
  default = [{
    effect = "NO_SCHEDULE"
    key    = "platform"
    value  = "true"
  }, ]
}


## Multi-tenant node pool: Blue

variable "enable_blue_mt_node_pool" {
  type        = bool
  default     = true
  description = "Turn on the blue multi-tenant node pool"
}

variable "blue_mt_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the blue multi-tenant node pool"
}

variable "machine_type_multi_tenant_blue" {
  default     = "n1-standard-16"
  description = "The GCP machine type for GKE worker nodes running multi-tenant workloads"
}

variable "disk_size_multi_tenant_blue" {
  default     = 200
  type        = number
  description = "Number of GB available on Nodes' local disks for the multi-tenant node pool, which runs Airflow deployments"
}

variable "max_node_count_multi_tenant_blue" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE multi-tenant node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "mt_node_pool_taints_blue" {
  description = "Taints to apply to the Multi-Tenant Node Pool "
  type        = list(any)
  default     = []
}

variable "enable_gvisor_blue" {
  type        = bool
  default     = false
  description = "Should this module configure the multi-tenant node pool for the gvisor runtime?"
}

## Multi-tenant node pool: Green

variable "enable_green_mt_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green multi-tenant node pool"
}

variable "green_mt_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the green multi-tenant node pool"
}

variable "machine_type_multi_tenant_green" {
  default     = "n1-standard-16"
  description = "The GCP machine type for GKE worker nodes running multi-tenant workloads"
}

variable "disk_size_multi_tenant_green" {
  default     = 200
  type        = number
  description = "Number of GB available on Nodes' local disks for the multi-tenant node pool, which runs Airflow components"
}

variable "max_node_count_multi_tenant_green" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE multi-tenant node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "mt_node_pool_taints_green" {
  description = "Taints to apply to the Multi-Tenant Node Pool"
  type        = list(any)
  default     = []
}

variable "enable_gvisor_green" {
  type        = bool
  default     = false
  description = "Should this module configure the multi-tenant node pool for the gvisor runtime?"
}

## Dynamic node pool (legacy, pre-dynamic-blue-green pool)

variable "create_dynamic_pods_nodepool" {
  type        = bool
  default     = false
  description = "If true, creates a NodePool for the pods spun up using KubernetesPodsOperator or KubernetesExecutor"
}

variable "dynamic_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the dynamic node pool"
}

variable "disk_size_dynamic" {
  default     = 200
  type        = number
  description = "Number of GB available on Nodes' local disks for the dynamic node pool, which runs Airflow deployments' ephemeral pods such as KubeExecutor pods and Kubernetes Pod Operator pods"
}

variable "dynamic_node_pool_taints" {
  description = "Taints to apply to the dynamic node pool "
  type        = list(any)
  default = [{
    effect = "NO_SCHEDULE"
    key    = "dynamic-pods"
    value  = "true"
  }, ]
}

variable "max_node_count_dynamic" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE dynamic node pool. The exact max will be 3 * ceil(your_value / 3.0) for a regional cluster, or exactly as configured for zonal cluster."
}

variable "enable_gvisor_dynamic" {
  type        = bool
  default     = false
  description = "Should this module configure the dynamic node pool for the gvisor runtime?"
}

variable "machine_type_dynamic" {
  default     = "n1-standard-16"
  description = "The GCP machine type for the bastion"
}

## Dynamic node pool blue (added 2020-12-16)

variable "enable_dynamic_blue_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the blue dynamic node pool"
}

variable "dynamic_blue_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the blue dynamic node pool"
}

variable "machine_type_dynamic_blue" {
  default     = "n1-standard-16"
  description = "The GCP machine type for the blue dynamic node pool"
}

variable "disk_size_dynamic_blue" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the blue dynamic node pool"
}

variable "max_node_count_dynamic_blue" {
  default     = 10
  description = "The approximate maximum number of nodes in the blue dynamic node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "dynamic_blue_node_pool_taints" {
  description = "Taints to apply to the blue dynamic node pool"
  type        = list(any)
  default = [{
    effect = "NO_SCHEDULE"
    key    = "dynamic-pods"
    value  = "true"
  }, ]
}

variable "enable_gvisor_dynamic_blue" {
  type        = bool
  default     = false
  description = "Should gvisor be enabled for the blue dynamic node pool?"
}

## Dynamic node pool green (added 2020-12-16)

variable "enable_dynamic_green_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green dynamic node pool"
}

variable "dynamic_green_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the green dynamic node pool"
}

variable "machine_type_dynamic_green" {
  default     = "n1-standard-16"
  description = "The GCP machine type for the green dynamic node pool"
}

variable "disk_size_dynamic_green" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the green dynamic node pool"
}

variable "max_node_count_dynamic_green" {
  default     = 10
  description = "The approximate maximum number of nodes in the green dynamic node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "dynamic_green_node_pool_taints" {
  description = "Taints to apply to the green dynamic node pool"
  type        = list(any)
  default = [{
    effect = "NO_SCHEDULE"
    key    = "dynamic-pods"
    value  = "true"
  }, ]
}

variable "enable_gvisor_dynamic_green" {
  type        = bool
  default     = false
  description = "Should gvisor be enabled for the green dynamic node pool?"
}

## Additional configs

variable "install_astronomer_helm_chart" {
  type        = bool
  default     = true
  description = "When false, this module skips installing the Astronomer helm chart. This is useful if you want to manage Astronomer outside of Terraform"
}

variable "enable_cloud_sql_proxy" {
  default = true
  type    = bool
}

variable "kube_api_whitelist_cidr" {
  default     = ""
  type        = string
  description = "If not provided, will whitelist only the calling IP, otherwise provide this CIDR block. This is ignore if var.management_endpoint is not set to 'public'"
}

variable "pod_security_policy_enabled" {
  default     = false
  type        = bool
  description = "Turn on pod security policies in the cluster"
}

variable "enable_spotinist" {
  default     = false
  type        = bool
  description = "Use Spotinist to run nodes"
}

variable "astronomer_namespace" {
  default     = "astronomer"
  type        = string
  description = "The namespace that will be created and Astronomer will be installed"
}
