variable "deployment_id" {}

variable "zonal" {
  default = true
}

module "astronomer_cloud" {
  source           = "../.."
  deployment_id    = var.deployment_id
  dns_managed_zone = "steven-zone"
  email            = "steven@astronomer.io"
  zonal_cluster    = var.zonal
  management_api   = "public"
}
