variable "base_domain" {
  default     = ""
  type        = string
  description = "if blank, will use from gcp module"
}

variable "stripe_secret_key" {
  default = ""
  type    = string
}

variable "stripe_pk" {
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

variable "enable_istio" {
  default = true
  type    = bool
}

variable "zonal_cluster" {
  default = false
  type    = bool
}

variable "management_api" {
  default = "private"
  type    = string
}

variable "enable_gvisor" {
  default = false
  type    = bool
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
