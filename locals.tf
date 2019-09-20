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
nginx:
  loadBalancerIP: ${module.gcp.load_balancer_ip == "" ? "~" : module.gcp.load_balancer_ip}
  # For cloud, the load balancer should be public
  privateLoadBalancer: false
  perserveSourceIP: true

astronomer:

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
      publicSignups: true
    %{if var.smtp_uri != ""}
      email:
        enabled: true
        smtpUrl: ${var.smtp_uri}
    %{endif}
      helm:
        env:
          - name: AIRFLOW__WEBSERVER__ANALYTICS_TOOL
            value: "metarouter"
          - name: AIRFLOW__WEBSERVER__ANALYTICS_ID
            value: "tH2XzkxCDpdC8Jvn8YroJ"
      deployments:
        maxExtraAu: 1000
        maxPodAu: 100
        components:
          - name: scheduler
            au:
              default: 5
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
%{if var.slack_alert_channel != "" && var.slack_alert_url != ""}
alertmanager:
  receivers:
    platform:
      slack_configs:
      - channel: "${var.slack_alert_channel}"
        api_url: "${var.slack_alert_url}"
        title: "{{ .CommonAnnotations.summary }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"
%{endif}

EOF

  extra_istio_helm_values = <<EOF
---
global:
  proxy:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 248Mi
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

}
