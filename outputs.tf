output "bastion_proxy_command" {
  value = module.gcp.bastion_proxy_command
}

output "application_url" {
  value = "https://app.${var.base_domain != "" ? var.base_domain : module.gcp.base_domain}/"
}
