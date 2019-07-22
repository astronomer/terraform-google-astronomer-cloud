variable "deployment_id" {}

variable "zonal" {}

variable "dns_managed_zone" {}

variable "kubeconfig_path" {
  default = ""
  type    = string
}

module "astronomer_cloud" {
  source           = "../.."
  deployment_id    = var.deployment_id
  dns_managed_zone = var.dns_managed_zone
  email            = "steven@astronomer.io"
  zonal_cluster    = var.zonal
  management_api   = "public"
  enable_gvisor    = false
  kubeconfig_path  = var.kubeconfig_path
}
