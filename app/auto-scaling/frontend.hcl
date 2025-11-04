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
  description = "The Namespace name to deploy the DB task"
  default = "frontend-team"
}
variable "frontend_max_instances" {
  description = "The maximum number of instances to scale up to."
  default     = 5
}

variable "frontend_max_scale_up" {
  description = "The maximum number of instances to scale up by."
  default     = 1
}

variable "frontend_max_scale_down" {
  description = "The maximum number of instances to scale down by."
  default     = 2
}
variable "frontend_port" {
  description = "Frontend Port"
  default = 3000
}
# Begin Job Spec

job "frontend" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace = var.nomad_ns
  group "frontend" {
    count = 1
    scaling {
      enabled = true
      min     = 1
      max     = var.frontend_max_instances

      policy {
        evaluation_interval = "5s"
        cooldown            = "10s"

        check "high-cpu-usage" {
          source = "nomad-apm"
          query = "max_cpu-allocated"

          strategy "target-value" {
            driver = "target-value"
            target = 20
            threshold = 0.0001
            max_scale_up = var.frontend_max_scale_up
            max_scale_down = var.frontend_max_scale_down
          }
        }
      }
    }  
    network {
      port "frontend" {
        static = var.frontend_port
      }
    }
    service {
      name = "frontend"
      provider = "consul"
      port = "frontend"
      check {
        name      = "Frontend ready"
        type      = "http"
        path      = "/"
        interval  = "5s"
        timeout   = "5s"
      }
    }
    task "frontend" {
      driver = "docker"
      meta {
        service = "frontend"
      }
      config {
        image = "hashicorpdemoapp/frontend-nginx:v1.0.9"
        ports = ["frontend"]
        mount {
          type   = "bind"
          source = "local/default.conf"
          target = "/etc/nginx/conf.d/default.conf"
        }
      }
      env {
          NEXT_PUBLIC_FOOTER_FLAG = "HashiCups instance ${NOMAD_ALLOC_INDEX}"
          NEXT_PUBLIC_PUBLIC_API_URL="/"
      }
      template {
        data =  <<EOF
server {
  listen {{ env "NOMAD_PORT_frontend" }};
  server_name localhost;
  server_tokens off;
  gzip on;
  gzip_proxied any;
  gzip_comp_level 4;
  gzip_types text/css application/javascript image/svg+xml;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection 'upgrade';
  proxy_set_header Host $host;
  proxy_cache_bypass $http_upgrade;
  location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
  }
  location /api {
    {{ range service "public-api" }}
      proxy_pass http://{{ .Address }}:{{ .Port }};
    {{ end }}
  }
}
        EOF
        destination = "local/default.conf"
      }
    }
  }
}