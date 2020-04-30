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
  astronomer_helm_values      = <<EOF
  global:
    # Replace to match your certificate, less the wildcard.
    # If you are using Let's Encrypt + Route 53, then it should be <deployment_id>.<route53_domain>
    # For example, astro.your-route53-domain.com
    baseDomain: sample.astronomer-development.com
    tlsSecret: astronomer-tls
  nginx:
    privateLoadBalancer: false
  astronomer:
    houston:
      config:
        publicSignups: false
  EOF

}
