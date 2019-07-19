variable "deployment_id" {}

variable "zonal" {}

variable "dns_managed_zone" {}

module "astronomer_cloud" {
  source           = "../.."
  deployment_id    = var.deployment_id
  dns_managed_zone = var.dns_managed_zone
  email            = "steven@astronomer.io"
  zonal_cluster    = var.zonal
  management_api   = "public"
  enable_gvisor    = false
}
