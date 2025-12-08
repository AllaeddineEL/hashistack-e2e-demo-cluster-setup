# -----------------------------+
# BASE CONFIG                  |
# -----------------------------+
plugin_dir = "C:\\nomad\\plugins"
datacenter = "_NOMAD_DATACENTER"
region = "_NOMAD_DOMAIN"

# Nomad node name
name = "_NOMAD_NODE_NAME"

# Data Persistence
data_dir = "C:\\nomad\\data"

# Logging
log_level = "INFO"
log_file = "C:\\nomad\\logs.txt"
log_rotate_bytes = 100000
log_rotate_max_files = 5
# enable_syslog = false
enable_debug = false

# -----------------------------+
# CLIENT CONFIG                |
# -----------------------------+

client {
  enabled = true
  options {
    "driver.raw_exec.enable" = 1
  }
  meta {
    _NOMAD_AGENT_META
  }
}

# -----------------------------+
# NETWORKING CONFIG            |
# -----------------------------+

bind_addr = "0.0.0.0"

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

# -----------------------------+
# MONITORING CONFIG            |
# -----------------------------+

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

# -----------------------------+
# INTEFRATIONS CONFIG          |
# -----------------------------+

# Consul              
# -----------------------------

consul {
  # Address of the local Consul agent.
  address               = "127.0.0.1:8500"
  # Token used to provide a per-request ACL token.
  token                 = "_CONSUL_AGENT_TOKEN"
  # Specifies if Nomad should advertise its services in Consul.
  auto_advertise        = true
  # Specifies the name of the service in Consul for the Nomad servers.
  client_service_name   = "nomad-client"
  # Specifies if the Nomad servers should join other Nomad servers using Consul.
  client_auto_join      = true
}

# Vault              
# -----------------------------

# vault {
#   enabled = true
#   address = "http://active.vault.service.consul:8200"
# }
vault {
  enabled = true
  address = "http://vault.service.dc1.global:8200"
   default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}
# -----------------------------+
# SECURITY CONFIG              |
# -----------------------------+

# Gossip Encryption              
# -----------------------------

# Not needed for Nomad clients.

# TLS Encryption              
# -----------------------------

tls {
  http      = true
  rpc       = true

  ca_file   = "C:\\nomad\\certs\\nomad-agent-ca.pem"
  cert_file = "C:\\nomad\\certs\\nomad-agent.pem"
  key_file  = "C:\\nomad\\certs\\nomad-agent-key.pem"

  verify_server_hostname = true
}

# ACL Configuration              
# -----------------------------

acl {
  enabled = true
}
