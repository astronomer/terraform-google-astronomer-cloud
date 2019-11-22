locals {
  astronomer_helm_values = <<EOF
---
global:
  # Base domain for all subdomains exposed through ingress
  baseDomain: ${var.base_domain != "" ? var.base_domain : module.gcp.base_domain}
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
    tolerations:
      - key: "platform"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
  deploymentNodePool:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: "astronomer.io/multi-tenant"
              operator: In
              values:
              - "true"
%{if var.enable_gvisor == true}
    tolerations:
    - effect: NoSchedule
      key: sandbox.gke.io/runtime
      operator: Equal
      value: gvisor
%{endif}
%{if var.enable_velero == true}
  veleroEnabled: true
%{endif}
nginx:
  loadBalancerIP: ${module.gcp.load_balancer_ip == "" ? "~" : module.gcp.load_balancer_ip}
  # For cloud, the load balancer should be public
  privateLoadBalancer: false
  perserveSourceIP: true
elasticsearch:
  data:
    heapMemory: 2g
    resources:
      limits:
        cpu:     2
        memory:  6Gi
      requests:
        cpu:     500m
        memory:  2Gi
    replicas: 4
astronomer:
  images:
    registry:
      repository: registry
      tag: 2.7.1
      pullPolicy: IfNotPresent
  orbit:
    env:
      - name: ANALYTICS_TRACKING_ID
        value: "tH2XzkxCDpdC8Jvn8YroJ"
  %{if var.stripe_secret_key != "" && var.stripe_pk != ""}
      - name: STRIPE_PK
        value: "${var.stripe_pk}"
  %{endif}
  houston:
    env:
      - name: AUTH__LOCAL__ENABLED
        value: "true"
    %{if var.stripe_secret_key != "" && var.stripe_pk != ""}
      - name: STRIPE__SECRET_KEY
        value: "${var.stripe_secret_key}"
      - name: STRIPE__ENABLED
        value: "true"
    %{endif}
    config:
      cors:
        allowedOrigins:
          - https://orbit-dev.netlify.com/
    %{if var.public_signups}
      publicSignups: true
    %{else}
      publicSignups: false
    %{endif}
    %{if var.smtp_uri != ""}
      email:
        enabled: true
        smtpUrl: ${var.smtp_uri}
    %{endif}
      deployments:
        maxExtraAu: 1000
        maxPodAu: 100
        sidecars:
          cpu: 400
          memory: 248
        components:
          - name: scheduler
            au:
              default: 10
              limit: 100
          - name: webserver
            au:
              default: 5
              limit: 100
          - name: statsd
            au:
              default: 2
              limit: 30
          - name: pgbouncer
            au:
              default: 2
              limit: 2
          - name: flower
            au:
              default: 2
              limit: 2
          - name: redis
            au:
              default: 2
              limit: 2
          - name: workers
            au:
              default: 10
              limit: 100
            extra:
              - name: terminationGracePeriodSeconds
                default: 600
                limit: 36000
              - name: replicas
                default: 1
                limit: 20
        %{if var.enable_istio}
        namespaceLabels:
          istio-injection: enabled
        %{endif}
        astroUnit:
          price: 10
        helm:
          webserver:
            initialDelaySeconds: 15
            timeoutSeconds: 30
            failureThreshold: 60
            periodSeconds: 8
          workers:
            resources:
              limits:
                ephemeral-storage: "10Gi"
              requests:
                ephemeral-storage: "1Gi"
          quotas:
            requests.ephemeral-storage: "50Gi"
            limits.ephemeral-storage: "256Gi"
          pgbouncer:
            resultBackendPoolSize: 10
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: "astronomer.io/multi-tenant"
                    operator: In
                    values:
                    - "true"
%{if var.enable_gvisor == true}
          tolerations:
          - effect: NoSchedule
            key: sandbox.gke.io/runtime
            operator: Equal
            value: gvisor
%{endif}
%{if var.create_dynamic_pods_nodepool == true}
          podMutation:
            tolerations:
              - key: "dynamic-pods"
                operator: "Equal"
                value: "true"
                effect: "NoSchedule"
            affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: "astronomer.io/dynamic-pods"
                          operator: In
                          values:
                            - "true"
%{endif}
%{if module.gcp.gcp_default_service_account_key != ""}
  registry:
    gcs:
      enabled: true
      bucket: ${module.gcp.container_registry_bucket_name}
%{endif}
%{if var.slack_alert_channel != "" && var.slack_alert_url != ""}
alertmanager:
  receivers:
    platform:
      slack_configs:
      - channel: "${var.slack_alert_channel}"
        api_url: "${var.slack_alert_url}"
        title: "{{ .CommonAnnotations.summary }}"
        text: |-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.summary }}
            *Description:* {{ .Annotations.description }}
            *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
%{if var.pagerduty_service_key != ""}
      pagerduty_configs:
      - routing_key: "${var.pagerduty_service_key}"
        description: "{{ .CommonAnnotations.summary }}"
%{endif}
    airflow:
      webhook_configs:
      - url: "http://astronomer-houston:8871/v1/alerts"
        send_resolved: true
      slack_configs:
      - channel: "${var.slack_alert_channel}"
        api_url: "${var.slack_alert_url}"
        title: "{{ .CommonAnnotations.summary }}"
        text: |-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.summary }}
            *Description:* {{ .Annotations.description }}
            *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
%{endif}
prometheus:
  # Configure resources
  resources:
    requests:
      cpu: "1000m"
      memory: "16Gi"
    limits:
      cpu: "4000m"
      memory: "32Gi"
EOF

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
  proxy:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 400m
        memory: 248Mi
kiali:
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
