output "bastion_proxy_command" {
  value = module.gcp.bastion_proxy_command
}

output "application_url" {
  value = "https://app.${module.gcp.base_domain}/"
}
