variable "project" {
  type = string
}

variable "dns_managed_zone" {
  type = string
}

variable "email" {
  type = string
}

variable "deployment_id" {
  type = string
}

variable "enable_istio" {
  default = true
}

variable "region" {
  default = "us-east4"
  type    = string
}

variable "zone" {
  default = "us-east4-a"
  type    = string
}

variable "acme_server" {
  default = "https://acme-v02.api.letsencrypt.org/directory"
  type    = string
}

