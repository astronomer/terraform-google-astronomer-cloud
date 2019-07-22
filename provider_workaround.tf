# this is a workaround to allow JIT
# initialization of these providers
# https://github.com/hashicorp/terraform/issues/2430

resource "local_file" "kubeconfig" {
  content  = module.gcp.kubeconfig
  filename = "./kubeconfig"
}

provider "kubernetes" {
  version          = "~> 1.8"
  config_path      = var.kubeconfig_path != "" ? var.kubeconfig_path : local_file.kubeconfig.filename
  load_config_file = true
}

provider "helm" {
  version         = "~> 0.10"
  service_account = "tiller"
  namespace       = "kube-system"
  install_tiller  = false
  kubernetes {
    config_path      = var.kubeconfig_path != "" ? var.kubeconfig_path : local_file.kubeconfig.filename
    load_config_file = true
  }
}
