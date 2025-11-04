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
      vault {
        role = "payments-transform-secret"
      }
      config {
        image   = "hashicorpdemoapp/payments:${var.payments_version}"
        ports = ["${var.payments_api_port}"]
      }
      resources {
        cpu    = 500
        memory = 500
      }
      env {
        SPRING_CONFIG_LOCATION = "file:/local/"
        SPRING_CLOUD_BOOTSTRAP_LOCATION = "file:/local/"
      }
      template {
        data = <<EOF
server.port=${var.payments_api_port}        
app.storage=db
app.encryption.enabled=true
app.encryption.path=transform
app.encryption.key=payments
EOF
        destination = "local/application.properties"
      }
      # Creation of the template file defining how to connect to vault
      template {
        destination   = "local/bootstrap.yml"
        data = <<EOF
spring:
  cloud:
    vault:
      enabled: true
      fail-fast: true
      authentication: TOKEN
      token: ${VAULT_TOKEN}
      {{ range service "vault" }}
      host: vault.service.dc1.global
      port: {{ .Port }}
      {{ end }}
      scheme: http
      kv:
        enabled: false
      generic:
        enabled: false
EOF
      }
      template {
        destination   = "local/application.yaml"
        data = <<EOF
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    url: jdbc:postgresql://product-api-db.virtual.global:5432/products
    username: {{with secret "database/creds/product-api-db-owner"}}{{.Data.username}}{{end}}
    password: {{with secret "database/creds/product-api-db-owner"}}{{.Data.password}}{{end}}
  jpa:
    hibernate:
      ddl-auto: update 
    show-sql: true
    database: postgresql
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    open-in-view: false
    generate-ddl: true
    properties:
      hibernate:
        temp:
          use_jdbc_metadata_defaults: false
management:
  endpoint:
    health:
      show-details: always
  endpoints:
    web:
      exposure:
        include: '*'
EOF
    }
  }

}
}