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

variable "payments_version" {
  description = "Docker version tag"
  default = "v0.0.16"
}

variable "nomad_ns" {
  description = "The Namespace name to deploy the DB task"
  default = "backend-team"
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

job "payments-api" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace   = var.nomad_ns

  group "payments-api" {
    count = 1
    network {
      mode = "bridge"
    }
    service {
      name = "payments-api"
      provider = "consul"
      port = "${var.payments_api_port}"

      connect {
        sidecar_service {
          proxy {
            transparent_proxy {
            }
          }
        }
      }

      check {
        name      = "Payments API ready"
        address_mode = "alloc"
        type      = "http"
        path			= "/actuator/health"
        interval  = "5s"
        timeout   = "5s"
        expose   = true
      }
    }
    task "payments-api" {
      driver = "docker"
      meta {
        service = "payments-api"
      }
      config {
        image   = "hashicorpdemoapp/payments:${var.payments_version}"
        ports = ["${var.payments_api_port}"]
        mount {
          type   = "bind"
          source = "local/application.properties"
          target = "/application.properties"
        }
      }
      resources {
        cpu    = 500
        memory = 500
      }
      template {
        data = "server.port=${var.payments_api_port}"
        destination = "local/application.properties"
      }
    }
  }

}