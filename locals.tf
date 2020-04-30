locals {
  astronomer_helm_values = var.astronomer_helm_values

  extra_istio_helm_values = <<EOF
---
global:
  # Allow Istio control plane to run on platform nodes...
  defaultTolerations:
  - key: "platform"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  # ... and require it to land on that node pool.
  defaultNodeSelector:
    astronomer.io/multi-tenant: "false"
  configRootNamespace: "istio-config"
  proxy:
    lifecycle:
      preStop:
       exec:
         command:
           - "/bin/bash"
           - "-c"
           - |
              set -e
              echo "Exit signal received, waiting for all network connections to clear..."
              while [ $(netstat -plunt | grep tcp | grep -v envoy | grep -v pilot | wc -l | xargs) -ne 0 ]; do
                printf "."
                sleep 3;
              done
              echo "Network connections cleared, shutting down pilot..."
              exit 0
    # https://github.com/istio/istio/issues/8247
    concurrency: 1
    # Only use sidecar for RFC1918 address space (private networks).
    # This will allow mesh-external traffic to leave the cluster
    # without going through a sidecar.
    includeIPRanges: "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 400m
        memory: 248Mi
kiali:
  enabled: true
tracing:
  enabled: true
gateways:
  istio-ingressgateway:
    enabled: false
# minimums above 1 to make
# single-pod interruption
# acceptable to the pod disruption
# budget
sidecarInjectorWebhook:
  replicaCount: 2
galley:
  replicaCount: 2
pilot:
  autoscaleMin: 2
security:
  replicaCount: 2
mixer:
  policy:
    autoscaleMin: 2
  telemetry:
    autoscaleMin: 2
EOF

  extra_velero_helm_values = <<EOF
---
# Allow Velero to run on platform nodes...
tolerations:
- key: "platform"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
# ... and require it to land on that node pool.
nodeSelector:
  astronomer.io/multi-tenant: "false"
configuration:
  provider: gcp
  backupStorageLocation:
    name: gcp
    bucket: "${module.gcp.gcp_velero_backups_bucket_name}"
  volumeSnapshotLocation:
    name: gcp
metrics:
  enabled: true
credentials:
  secretContents:
    cloud: |-
      ${indent(6, module.gcp.gcp_velero_service_account_key)}
schedules:
  astronomer-platform:
    schedule: "0 2 * * *"
    template:
      ttl: "720h"
      includedNamespaces:
        - astronomer
  full-back-up:
    schedule: "0 4 * * *"
    template:
      ttl: "720h"
EOF

  extra_googlesqlproxy_helm_values = <<EOF
---
replicasCount: 10
podAnnotations:
  sidecar.istio.io/proxyCPU: "1000m"
  sidecar.istio.io/proxyMemory: "300Mi"
  cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
EOF
  extra_kubecost_helm_values       = <<EOF
---
prometheus:
  server:
    persistentVolume:
      # default of 32Gi was exhausted
      size: 300Gi
EOF


  tiller_tolerations = [
    {
      key      = "platform",
      operator = "Equal",
      value    = "true",
      effect   = "NoSchedule"
    }
  ]

  tiller_node_selectors = {
    "astronomer.io/multi-tenant" = "false"
  }
}
