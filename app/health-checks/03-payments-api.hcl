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

# Begin Job Spec

job "payments-api" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace   = var.nomad_ns

  group "payments-api" {
    count = 1
    network {
      port "payments-api" {
      }
    }
    service {
        name = "payments-api"
        provider = "consul"
        port = "payments-api"
        check {
          name      = "Payments API ready"
					type      = "http"
          path			= "/actuator/health"
					interval  = "5s"
					timeout   = "5s"
        }
    }
    task "payments-api" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      meta {
        service = "payments-api"
      }
      config {
        image   = "hashicorpdemoapp/payments:${var.payments_version}"
        ports = ["payments-api"]
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
        data = <<EOH
server.port={{ env "NOMAD_PORT_payments_api" }}
EOH
        destination = "local/application.properties"
      }
    }
  }

}