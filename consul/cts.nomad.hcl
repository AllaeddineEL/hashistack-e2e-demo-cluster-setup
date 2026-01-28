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
  description = "The Namespace name to deploy the CTS task"
  default = "boundary"
}
variable "boundary_addr" {

}
variable "boundary_auth_method_id" {

}
variable "boundary_login_name" {

}
variable "boundary_login_password" {

}

job "consul-terraform-sync" {
  region = var.region
  datacenters = var.datacenters
  namespace   = var.nomad_ns
  type        = "service"
  group "cts" {
    count = 1
    network {
      mode = "bridge"
      port "cts" {}
    }
    // volume "consul-api" {
    //   type   = "host"
    //   source = "consul-api"
    // }
    task "agent" {
      driver = "docker"
      config {
        image = "hashicorp/consul-terraform-sync:0.7"
        args = [
          "consul-terraform-sync",
          "start",
          "-config-file=${NOMAD_SECRETS_DIR}/cts.hcl"
        ]
      }
      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
    //   volume_mount {
    //     volume      = "consul-api"
    //     destination = "${NOMAD_SECRETS_DIR}/consul"
    //   }
      
      template {
        destination = "${NOMAD_SECRETS_DIR}/cts.env"
        env         = true
        data        = <<-EOT
          BOUNDARY_ADDR="${var.boundary_addr}"
          BOUNDARY_AUTH_METHOD_ID="${var.boundary_auth_method_id}"
          BOUNDARY_AUTHENTICATE_PASSWORD_LOGIN_NAME="${var.boundary_login_name}"
          BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD="${var.boundary_login_password}"
        EOT
      }
      # TODO: Migrate Consul credentials to Nomad workload identity
      template {
        destination = "${NOMAD_SECRETS_DIR}/cts.hcl"
        data        = <<-EOT
          port = {{ env "NOMAD_PORT_cts" }}
          consul {
            address = "unix://{{ env "NOMAD_SECRETS_DIR" }}/consul/consul.sock"
          }
          task {
            name        = "cts-boundary"
            description = "Pushes port-forwarding rules to Unifi Network"
            enabled     = true
            providers   = ["boundary"]
            module      = "hashicorp-dev-advocates/cts/boundary"
            version     = "1.0.0"
            condition "services" {
              regexp = ".*"
              filter = "Service.Meta contains \"boundary_enabled\" and Service.Meta contains \"true\""
            }
          }
          driver "terraform" {
            log         = false
    
            backend "consul" {
              gzip = true
            }

            required_providers {
              boundary = {
                source  = "hashicorp/boundary"
                version = "~> 1.1.15"
              }
            }
          }
        EOT
      }
    }
  }
}