Kind = "api-gateway"
Name = "api-gateway"

// Each listener configures a port which can be used to access the Consul cluster
Listeners = [
  {
    Port     = 5555
    Name     = "hashicups-db-tcp-route"
    Protocol = "tcp"
  },
  {
    Port     = 8088
    Name     = "hashicups-http-route"
    Protocol = "http"
  }
]