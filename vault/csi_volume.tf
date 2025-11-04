data "nomad_plugin" "gcepd" {
  plugin_id        = "gcepd"
  wait_for_healthy = true
}

resource "nomad_csi_volume" "vault_volume" {
  count      = 3
  depends_on = [data.nomad_plugin.gcepd]
  namespace  = "vault-cluster"
  # lifecycle {
  #   prevent_destroy = true
  # }

  plugin_id    = data.nomad_plugin.gcepd.plugin_id
  volume_id    = "vault-volume[${count.index}]"
  name         = "vault-volume-${count.index}"
  capacity_min = "10GB"
  capacity_max = "20GB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "ext4"
  }

  topology_request {
    required {
      topology {
        segments = {
          "topology.gke.io/zone" = var.zone
        }
      }
    }
  }
}
