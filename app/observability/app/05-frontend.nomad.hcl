variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}
variable "nomad_ns" {
  description = "The Namespace name to deploy the DB task"
  default = "frontend-team"
}
variable "product_api_port" {
  description = "Product API Port"
  default = 9090
}

variable "frontend_port" {
  description = "Frontend Port"
  default = 3000
}

variable "payments_api_port" {
  description = "Payments API Port"
  default = 8080
}

variable "public_api_port" {
  description = "Public API Port"
  default = 8081
}

variable "nginx_port" {
  description = "Nginx Port"
  default = 80
}

variable "db_port" {
  description = "Postgres Database Port"
  default = 5432
}
# Begin Job Spec

job "frontend" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace = var.nomad_ns
  group "frontend" {
    count = 1
    network {
      mode = "bridge"
      port "expose" {}     
      port "envoy_metrics" {
        to = 9102
      }
    }
    service {
      name = "frontend"
      provider = "consul"
      port = "${var.frontend_port}"
      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
      connect {
        sidecar_service {
          proxy {
            expose {
              path {
                path            = "/metrics"
                protocol        = "http"
                local_path_port = 9102
                listener_port   = "envoy_metrics"
              }
            }
            transparent_proxy {
            }
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }
          }
        }
      }
      check {
        name      = "Frontend ready"
        address_mode = "alloc"
        type      = "http"
        path      = "/"
        interval  = "5s"
        timeout   = "5s"
        expose   = true
      }
    }
    task "frontend" {
      driver = "docker"
      meta {
        service = "frontend"
      }
      config {
        image = "hashicorpdemoapp/frontend:v1.0.9"
        ports = ["${var.frontend_port}"]
      }
      env {
          NEXT_PUBLIC_FOOTER_FLAG = "HashiCups instance ${NOMAD_ALLOC_INDEX}"
          NEXT_PUBLIC_PUBLIC_API_URL="/"
          PORT="${var.frontend_port}"
      }      
    }
  }
}