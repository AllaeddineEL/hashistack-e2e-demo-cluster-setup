namespace = "observability"
prometheus_task_services = [{
    service_port_label = "http",
    service_name       = "prometheus-server",
    service_tags       = [],
    check_enabled      = true,
    check_path         = "/-/healthy",
    check_interval     = "3s",
    check_timeout      = "1s",
  }]
prometheus_task_app_prometheus_yaml = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'Consul Connect Metrics'
    metrics_path: "/metrics"
    consul_sd_configs:
    - server: '172.17.0.1:8500'
    relabel_configs:
      - source_labels: [__meta_consul_service]
        action: drop
        regex: (.+)-sidecar-proxy
      - source_labels: [__meta_consul_service_metadata_envoy_metrics_port]
        action: keep
        regex: (.+)
      - source_labels: [__address__, __meta_consul_service_metadata_envoy_metrics_port]
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

  - job_name: 'nomad_metrics'
    scheme: https
    tls_config:
      insecure_skip_verify: true
    consul_sd_configs:
    - server: '172.17.0.1:8500'
      services: ['nomad-client', 'nomad']
    relabel_configs:
      - source_labels: ['__meta_consul_tags']
        regex: '(.*)http(.*)'
        action: keep
    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']     
EOH