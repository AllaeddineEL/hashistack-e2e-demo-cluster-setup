variable "nomad_ns" {
  description = "The Namespace name to deploy the DB task"
  default = "observability"
}

job "grafana" {
  type = "service"
  namespace   = var.nomad_ns
  group "grafana" {
    count = 1

    network {
      mode = "bridge"
      port "grafana" {
         to = "3000"
      }
    }

    service {
      name = "grafana"
      port = "grafana"
      meta {
        metrics_port = "${NOMAD_HOST_PORT_expose}"
      }

      check {
        type     = "http"
        name     = "grafana"
        path     = "/api/health"
        interval = "30s"
        timeout  = "10s"
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"

        volumes = [
          "local/provisioning/prom.yml:/etc/grafana/provisioning/datasources/prometheus.yml"
        ]
      }



      env {
        GF_PATHS_CONFIG = "/local/config.ini"
        GF_PATHS_PROVISIONING = "/local/provisioning"
      }

      template {
        destination = "local/config.ini"
        data        = <<EOF
[database]
type = sqlite3
EOF
      }

      template {
        destination = "local/provisioning/datasources/prom.yml"
        data        = <<EOF
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  {{- range service "prometheus-server" }}
  url: http://{{ .Address }}:{{ .Port }}
  {{- end }}
  isDefault: true
  editable: false
- name: Loki
  type: loki
  access: proxy
  {{- range service "loki" }}
  url: http://{{ .Address }}:{{ .Port }}
  {{- end }}
EOF         
      perms = "777"
      }
      template {
        data        = <<EOF
apiVersion: 1
providers:
  - name: dashboards
    type: file
    updateIntervalSeconds: 30
    options:
      foldersFromFilesStructure: true
      path: /local/provisioning/dashboards
EOF
        destination = "/local/provisioning/dashboards/dashboards.yaml"
      }
      template {
        data            = file(abspath("./dashboards/allocations.json"))
        destination     = "local/provisioning/dashboards/nomad/allocations.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
      template {
        data            = file(abspath("./dashboards/clients.json"))
        destination     = "local/provisioning/dashboards/nomad/clients.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
      template {
        data            = file(abspath("./dashboards/server.json"))
        destination     = "local/provisioning/dashboards/nomad/server.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
      template {
        data            = file(abspath("./dashboards/consulservicedashboard.json"))
        destination     = "local/provisioning/dashboards/consul/consulservicedashboard.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
      template {
        data            = file(abspath("./dashboards/consulservicetoservicedashboard.json"))
        destination     = "local/provisioning/dashboards/consul/consulservicetoservicedashboard.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
    }
  }
}
