job "controller" {
  namespace   = "nomad-system"
  datacenters = ["dc1"]
  group "controller" {
    task "plugin" {
      driver = "docker"
      template {
        data = <<EOH
{{ key "service_account" }}
EOH
  destination = "secrets/creds.json"
      }
       env {
           GOOGLE_APPLICATION_CREDENTIALS = "/secrets/creds.json"
        }
      config {
        image = "registry.k8s.io/cloud-provider-gcp/gcp-compute-persistent-disk-csi-driver:v1.13.2"
       args = [
          "--endpoint=unix:///csi/csi.sock",
          "--v=6",
          "--logtostderr",
          "--run-node-service=false"
        ]
      }
      csi_plugin {
        id        = "gcepd"
        type      = "controller"
        mount_dir = "/csi"
      }
      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}