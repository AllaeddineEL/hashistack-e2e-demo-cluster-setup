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

variable "product_api_version" {
  description = "Docker version tag"
  default = "v0.0.22"
}

variable "postgres_db" {
  description = "Postgres DB name"
  default = "products"
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

job "product-api" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace   = var.nomad_ns

  group "product-api" {
    count = 1
    network {
      mode = "bridge"
    }
    service {
      name = "product-api"
      provider = "consul"
      port = "${var.product_api_port}"
      connect {
        sidecar_service {
          proxy {
            transparent_proxy {
            }
          }
        }
      }
      # DB connectivity check 
      check {
        name        = "DB connection ready"
        address_mode = "alloc"
        type      = "http" 
        path      = "/health/readyz" 
        interval  = "5s"
        timeout   = "5s"
        expose   = true
      }

      # Server ready check
      check {
        name        = "Product API ready"
        address_mode = "alloc"
        type      = "http" 
        path      = "/health/livez" 
        interval  = "5s"
        timeout   = "5s"
        expose   = true
      }
    }
    task "product-api" {
      driver = "docker"
      
      meta {
        service = "product-api"
      }
      vault {
        role = "postgressql-dynamic-secret"
      }
      config {
        image   = "hashicorpdemoapp/product-api:${var.product_api_version}"
        ports = ["${var.product_api_port}"]
      }
      template {
        data        = <<EOH
{{ range service "product-api-db" }}
DB_CONNECTION="host=product-api-db.virtual.global port={{ .Port }} user={{with secret "database/creds/product-api-db-owner"}}{{.Data.username}}{{end}} password={{with secret "database/creds/product-api-db-owner"}}{{.Data.password}}{{end}} dbname=${var.postgres_db} sslmode=disable"
{{ end }}
BIND_ADDRESS = "0.0.0.0:${var.product_api_port}"
EOH
        destination = "secrets/env"
        env         = true
      }
    }
  }

}