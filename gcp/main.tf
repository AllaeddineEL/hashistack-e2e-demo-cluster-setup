resource "google_compute_network" "hashistack" {
  name = "hashistack-${var.name}"
}

resource "google_compute_firewall" "consul_nomad_ui_ingress" {
  name          = "${var.name}-ui-ingress"
  network       = google_compute_network.hashistack.name
  source_ranges = [var.allowlist_ip]

  # Nomad
  allow {
    protocol = "tcp"
    ports    = [4646]
  }

  # Consul
  allow {
    protocol = "tcp"
    ports    = [8500]
  }
  # Consul HTTPS
  allow {
    protocol = "tcp"
    ports    = [8443]
  }
}

resource "google_compute_firewall" "ssh_ingress" {
  name          = "${var.name}-ssh-ingress"
  network       = google_compute_network.hashistack.name
  source_ranges = [var.allowlist_ip]

  # SSH
  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_all_internal" {
  name        = "${var.name}-allow-all-internal"
  network     = google_compute_network.hashistack.name
  source_tags = ["auto-join"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "clients_ingress" {
  name          = "${var.name}-clients-ingress"
  network       = google_compute_network.hashistack.name
  source_ranges = [var.allowlist_ip]
  target_tags   = ["nomad-clients"]

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  # nginx example; replace with your application port
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8200", "5555", "8088"]
  }
}

data "google_compute_image" "hashistack_image" {

  most_recent = true
  filter      = "name eq ^hashistack.*"

}
# resource "random_uuid" "consul_token" {
#   count = 2
# }

resource "google_compute_instance" "server" {
  count        = var.server_count
  name         = "${var.name}-server-${count.index}"
  machine_type = var.server_instance_type
  zone         = var.zone
  tags         = ["auto-join"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.hashistack_image.self_link
      size  = var.root_block_device_size
    }
  }

  network_interface {
    network = google_compute_network.hashistack.name
    # access_config {
    #   // Leave empty to get an ephemeral public IP
    # }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata_startup_script = templatefile("${path.module}/../shared/data-scripts/user-data-server.sh", {
    server_count   = var.server_count
    region         = var.region
    cloud_env      = "gce"
    retry_join     = var.retry_join
    lb_ip          = google_compute_forwarding_rule.servers_default.ip_address
    nomad_license  = file("/root/license/license.nomad")
    consul_license = file("/root/license/license.consul")

    domain           = var.domain,
    datacenter       = var.datacenter,
    server_count     = "${var.server_count}",
    consul_node_name = "consul-server-${count.index}",

    consul_encryption_key   = random_id.consul_gossip_key.b64_std,
    consul_management_token = random_uuid.consul_mgmt_token.result,
    nomad_node_name         = "nomad-server-${count.index}",
    nomad_encryption_key    = random_id.nomad_gossip_key.b64_std,
    nomad_management_token  = random_uuid.nomad_mgmt_token.result,
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}"),
    agent_certificate       = base64gzip("${tls_locally_signed_cert.server_cert[count.index].cert_pem}"),
    agent_key               = base64gzip("${tls_private_key.server_key[count.index].private_key_pem}")
  })
  metadata = {
    "ssh-keys" = <<EOT
      ubuntu:${trimspace(tls_private_key.ssh_key.public_key_openssh)}
     EOT
  }

}

resource "google_compute_instance" "client" {
  count        = var.client_count
  name         = "${var.name}-client-${count.index}"
  machine_type = var.client_instance_type
  zone         = var.zone
  tags         = ["auto-join", "nomad-clients"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.hashistack_image.self_link
      size  = var.root_block_device_size
    }
  }

  network_interface {
    network = google_compute_network.hashistack.name
    # access_config {
    #   // Leave empty to get an ephemeral public IP
    # }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "logging-write",
      "cloud-platform",
      "compute-rw",
      "userinfo-email",
      "storage-ro"
    ]
  }

  metadata_startup_script = templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
    region     = var.region
    cloud_env  = "gce"
    retry_join = var.retry_join

    domain           = var.domain,
    datacenter       = var.datacenter,
    consul_node_name = "consul-client-${count.index}",

    consul_encryption_key = random_id.consul_gossip_key.b64_std,
    consul_agent_token    = "${data.consul_acl_token_secret_id.consul-client-agent-token[count.index].secret_id}",
    consul_default_token  = "${data.consul_acl_token_secret_id.consul-client-default-token[count.index].secret_id}",
    nomad_node_name       = "nomad-client-${count.index}",
    nomad_agent_meta      = "isPublic = false"
    nomad_agent_token     = "${data.consul_acl_token_secret_id.nomad-client-consul-token[count.index].secret_id}",
    ca_certificate        = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}"),
    agent_certificate     = base64gzip("${tls_locally_signed_cert.client_cert[count.index].cert_pem}"),
    agent_key             = base64gzip("${tls_private_key.client_key[count.index].private_key_pem}")
  })
}
resource "google_compute_forwarding_rule" "servers_default" {
  project               = var.project
  name                  = var.name
  target                = google_compute_target_pool.servers.self_link
  load_balancing_scheme = "EXTERNAL"
}
resource "google_compute_target_pool" "servers" {
  name = "servers-pool"

  instances = [
    "${var.zone}/${var.name}-server-0",
    "${var.zone}/${var.name}-server-1",
    "${var.zone}/${var.name}-server-2"
  ]

}
resource "google_compute_router" "router" {
  name    = "hashistack-${var.name}"
  region  = var.region
  network = google_compute_network.hashistack.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "hashistack-${var.name}"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
resource "google_compute_forwarding_rule" "clients_default" {
  project               = var.project
  name                  = "clients-${var.name}"
  target                = google_compute_target_pool.client.self_link
  load_balancing_scheme = "EXTERNAL"
}
resource "google_compute_target_pool" "client" {
  name = "client-pool"

  instances = google_compute_instance.client.*.self_link

}
