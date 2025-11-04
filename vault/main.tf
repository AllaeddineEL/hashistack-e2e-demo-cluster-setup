
resource "nomad_job" "vault" {
  #jobspec          = file("vault.nomad.hcl")

  purge_on_destroy = true
  jobspec          = <<EOT

job "vault-cluster" {
  namespace   = "vault-cluster"
  datacenters = ["dc1"]
  type        = "service"


  group "vault" {
    count = 3

    volume "vault_data" {
      type            = "csi"
      read_only       = false
      source          = "vault-volume"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      per_alloc       = true
    }

    network {

      mode = "host"

      port "api" {
        to     = "8200"
        static = "8200"
      }

      port "cluster" {
        to     = "8201"
        static = "8201"
      }
    }

    task "vault" {
      driver = "docker"
      template {
        data = <<EOH
        ${base64decode(data.terraform_remote_state.local.outputs.kms_sa_key)}
  EOH
  destination = "secrets/creds.json"
      }
       env {
           GOOGLE_APPLICATION_CREDENTIALS = "/secrets/creds.json"
           VAULT_LICENSE = <<EOH
           ${file("/root/license/license.vault")}
  EOH
        } 
      volume_mount {
        volume      = "vault_data"
        destination = "$${NOMAD_ALLOC_DIR}/vault/data"
        read_only   = false
      }

      config {
        image      = "hashicorp/vault-enterprise:1.17.4-ent"
        privileged = true
        network_mode = "host"
        ports = [
          "api",
          "cluster"
        ]

        volumes = [
          "local/config:/vault/config"
        ]

        command = "/bin/sh"
        args = [
          "-c",
          "vault operator init -status; if [ $? -eq 2 ]; then echo 'Vault is not initialized, starting in server mode...'; vault server -config=/vault/config; else echo 'Vault is already initialized, starting in server mode...'; vault server -config=/vault/config; fi"
        ]
      }

      template {
        data = <<EOH
ui = true
cluster_name = "nomad-vault-demo"
listener "tcp" {
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable     = "true"
}

storage "raft" {
  node_id = "{{ env "NOMAD_ALLOC_NAME" }}"
  path    = "{{ env "NOMAD_ALLOC_DIR" }}/vault/data"

{{- range service "vault" }}
  retry_join {
    auto_join_scheme = "http" 
    leader_api_addr = "http://{{ .Address }}:{{ .Port }}"
  }
  {{- end }}
}

cluster_addr = "http://{{ env "NOMAD_IP_cluster" }}:8201"
api_addr     = "http://{{ env "NOMAD_IP_api" }}:8200"

seal "gcpckms" {
  project     = "${data.terraform_remote_state.local.outputs.gcp_project}"
  region      = "${data.terraform_remote_state.local.outputs.keyring_location}"
  key_ring    = "${data.terraform_remote_state.local.outputs.key_ring}"
  crypto_key  = "${data.terraform_remote_state.local.outputs.crypto_key}"
}
EOH

        destination = "local/config/config.hcl"
        change_mode = "noop"
      }

      service {
        name     = "vault"
        port     = "api"
        provider = "consul"

        check {
          name     = "vault-api-health-check"
          type     = "http"
          path     = "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 1024

      }

      affinity {
        attribute = "$${meta.node_id}"
        value     = "$${NOMAD_ALLOC_ID}"
        weight    = 100
      }
    }
  }
}
  EOT

  depends_on = [
    nomad_csi_volume.vault_volume
  ]
}
