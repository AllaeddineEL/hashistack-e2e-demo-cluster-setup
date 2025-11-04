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

# Begin Job Spec

job "product-api" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace   = var.nomad_ns

  group "product-api" {
    count = 1
    network {
      port "product-api" {
      }
    }
    service {
        name = "product-api"
        provider = "consul"
        port = "product-api"
        # DB connectivity check 
        check {
          name        = "DB connection ready"
					type      = "http" 
          path      = "/health/readyz" 
					interval  = "5s"
					timeout   = "5s"
        }

        # Server ready check
        check {
          name        = "Product API ready"
          type      = "http" 
          path      = "/health/livez" 
          interval  = "5s"
          timeout   = "5s"
        }
    }
    task "product-api" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      
      meta {
        service = "product-api"
      }
       vault {
        role = "postgressql-dynamic-secret"
      }
      config {
        image   = "hashicorpdemoapp/product-api:${var.product_api_version}"
        ports = ["product-api"]
      }
      template {
        data        = <<EOH
{{ range service "product-api-db" }}
DB_CONNECTION="host={{ .Address }} port={{ .Port }} user={{with secret "database/creds/product-api-db-owner"}}{{.Data.username}}{{end}} password={{with secret "database/creds/product-api-db-owner"}}{{.Data.password}}{{end}} dbname=${var.postgres_db} sslmode=disable"
BIND_ADDRESS = "0.0.0.0:{{ env "NOMAD_PORT_product_api" }}"
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }
    }
  }

}