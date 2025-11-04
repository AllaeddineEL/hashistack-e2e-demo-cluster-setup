namespace = "observability"
config_file = "./promtail-config.yaml"
resources = {
    cpu    = 50,
    memory = 100
  }
container_args = [
          "-config.file=/etc/promtail/promtail-config.yaml",
          "-log.level=info",
          "-server.http-listen-port=$${NOMAD_PORT_http}"
]  