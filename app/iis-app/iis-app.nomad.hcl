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
  description = "The Namespace name to deploy the IIS task"
  default = "win-team"
}

job "sample-iis" {
  region = var.region
  datacenters = var.datacenters
  namespace   = var.nomad_ns
  vault {
    role         = "iis-dynamic-pki"
    policies     = ["vault-iis-agent"]
    change_mode  = "noop"
    env          = false
    disable_file = true
  }

  group "app" {
    count = 1

    # See: https://nomad-iis.sevensolutions.cc/docs/tips-and-tricks/in-place-update
    # disconnect {
    #  lost_after = "1m"
    # }

    network {
      port "httplabel" {}
    }
    service {
      name = "iis-sample-app"
      provider = "consul"
      port = "httplabel"
    }

    task "app" {
      driver = "iis"
      template {
        data = <<EOH
{{- with pkiCert "pki_int/issue/win-iis" "common_name=iis-sample-app.service.dc1.global" "private_key_format=pkcs8" -}}
{{ .Cert }}
{{ if .Key }}
{{ .Key }}
{{ end }}
{{ end }}
EOH
        destination = "${NOMAD_SECRETS_DIR}/certificate.pem"
        change_mode = "restart"
      }

      artifact {
        source = "https://github.com/sevensolutions/nomad-iis/raw/main/examples/static-sample-app.zip"
        destination = "local"
      }

      config {
        applicationPool {
          identity = "ApplicationPoolIdentity"
        }

        application {
          path = "local"
        }

        binding {
          type = "https"
          port = "httplabel"
          certificate {
            cert_file = "${NOMAD_SECRETS_DIR}/certificate.pem"
            key_file = "${NOMAD_SECRETS_DIR}/certificate.pem"
          }
        }
      }

      resources {
        cpu    = 100
        memory = 20
      }
    }
  }
}