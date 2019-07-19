locals {
  astronomer_helm_values = <<EOF
---
global:
  # Base domain for all subdomains exposed through ingress
  baseDomain: ${module.gcp.base_domain}
  tlsSecret: astronomer-tls
  istioEnabled: ${var.enable_istio == true ? true : false}

  # the platform components go in the non-multi tenant
  # node pool, regardless of if we are using gvisor or not
  platformNodePool:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: "astronomer.io/multi-tenant"
              operator: In
              values:
              - "false"

  # the deployment components don't get scheduled into the
  # non-multi-tenant node pool, regardless of if we are
  # using gvisor or not
  deploymentNodePool:
    affinity:
      nodeAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: "astronomer.io/multi-tenant"
              operator: In
              values:
              - "false"
%{if var.enable_gvisor == true}
    tolerations:
    - effect: NoSchedule
      key: sandbox.gke.io/runtime
      operator: Equal
      value: gvisor
%{endif}

nginx:
  loadBalancerIP: ${module.gcp.load_balancer_ip == "" ? "~" : module.gcp.load_balancer_ip}
  # For cloud, the load balancer should be public
  privateLoadBalancer: false
  perserveSourceIP: true

astronomer:
  houston:
    config:
    %{if var.smtp_uri != ""}
      email:
        enabled: true
        smtpUrl: ${var.smtp_uri}
    %{endif}
      deployments:
        helm:
          affinity:
            nodeAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: "astronomer.io/multi-tenant"
                    operator: In
                    values:
                    - "false"
%{if var.enable_gvisor == true}
          tolerations:
          - effect: NoSchedule
            key: sandbox.gke.io/runtime
            operator: Equal
            value: gvisor
          webserver:
            runtimeClassName: gvisor
          scheduler:
            runtimeClassName: gvisor
          workers:
            runtimeClassName: gvisor
%{endif}
%{if module.gcp.gcp_default_service_account_key != ""}
  registry:
    gcs:
      enabled: true
      bucket: ${module.gcp.container_registry_bucket_name}
%{endif}  

EOF
}
