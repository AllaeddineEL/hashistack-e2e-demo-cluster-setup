output "lb_address_consul_nomad" {
  value = "http://${google_compute_forwarding_rule.servers_default.ip_address}"
}
output "lb_address_api_gateway" {
  value = google_compute_forwarding_rule.clients_default.ip_address
}
output "gcp_project" {
  value = var.project
}
output "keyring_location" {
  value = google_kms_key_ring.key_ring.location
}
output "key_ring" {
  value = google_kms_key_ring.key_ring.name
}
output "crypto_key" {
  value = google_kms_crypto_key.crypto_key.name
}
output "kms_sa_key" {
  sensitive = true
  value     = google_service_account_key.vault_kms_service_account_key.private_key
}
resource "local_file" "environment_variables" {
  filename = "datacenter.env"
  content  = <<-EOT
    export CONSUL_HTTP_ADDR="https://${google_compute_forwarding_rule.servers_default.ip_address}:8443"
    export CONSUL_HTTP_TOKEN="${random_uuid.consul_mgmt_token.result}"
    export CONSUL_HTTP_SSL="true"
    export CONSUL_CACERT="${path.cwd}/certs/datacenter_ca.cert"
    export CONSUL_TLS_SERVER_NAME="consul.${var.datacenter}.${var.domain}"
    export NOMAD_ADDR="https://${google_compute_forwarding_rule.servers_default.ip_address}:4646"
    export NOMAD_TOKEN="${random_uuid.nomad_mgmt_token.result}"
    export NOMAD_CACERT="${path.cwd}/certs/datacenter_ca.cert"
    export NOMAD_TLS_SERVER_NAME="nomad.${var.datacenter}.${var.domain}"
  EOT
}
