output "bastion_proxy_command" {
  value = module.gcp.bastion_proxy_command
}

output "application_url" {
  value = "https://app.${var.base_domain != "" ? var.base_domain : module.gcp.base_domain}/"
}

output "container_registry_bucket_name" {
  value = module.gcp.container_registry_bucket_name
}

output "load_balancer_ip" {
  value = module.gcp.load_balancer_ip
}
