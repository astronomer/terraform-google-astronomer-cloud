provider "google" {
  version = "~> 2.7"
  region  = var.region
  project = var.project
  zone    = var.zone
}

provider "google-beta" {
  # TODO: after GKE sandbox supported by
  # provider google-beta
  # until now, we are using a local,
  # re-compiled binary
  # version = "~> 2.7"
  region  = var.region
  project = var.project
  zone    = var.zone
}

provider "acme" {
  version    = "~> 1.3"
  server_url = var.acme_server
}

provider "random" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.0"
}

provider "null" {
}

provider "kubernetes" {
  config_path      = module.gcp.kubeconfig_filename
  load_config_file = true
}

provider "helm" {
  service_account = "tiller"
  namespace       = "kube-system"
  install_tiller  = true
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.14.1"
  kubernetes {
    config_path = module.gcp.kubeconfig_filename
    load_config_file = true
  }
}
