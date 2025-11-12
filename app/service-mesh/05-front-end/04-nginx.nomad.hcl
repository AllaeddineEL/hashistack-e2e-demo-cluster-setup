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
variable "product_api_port" {
  description = "Product API Port"
  default = 9090
}

variable "frontend_port" {
  description = "Frontend Port"
  default = 3000
}

variable "payments_api_port" {
  description = "Payments API Port"
  default = 8080
}

variable "public_api_port" {
  description = "Public API Port"
  default = 8081
}

variable "nginx_port" {
  description = "Nginx Port"
  default = 8080
}

variable "db_port" {
  description = "Postgres Database Port"
  default = 5432
}
# Begin Job Spec

job "nginx-reverse-proxy" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters
  namespace = var.nomad_ns
  group "nginx" {
    count = 1
    network {
      mode = "bridge"
    }
    service {
      name = "nginx"
      provider = "consul"
      port = "${var.nginx_port}"
      connect {
        sidecar_service {
          proxy {
            transparent_proxy {
            }
          }
        }
      }
      check {
        name      = "NGINX ready"
        type      = "http"
        path			= "/health"
        address_mode = "alloc"
        interval  = "5s"
        timeout   = "5s"
        expose   = true
      }
    }
    task "nginx" {
      driver = "docker"
      meta {
        service = "nginx-reverse-proxy"
      }
      config {
        image = "bitnami/nginx:latest"
        ports = ["${var.nginx_port}"]
        #network_mode = "host"
        mount {
          type   = "bind"
          source = "local/nginx.conf"
          target = "/opt/bitnami/nginx/conf/server_blocks/nginx.conf"
        }
      }
      template {
        data =  <<EOF
            proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=STATIC:10m inactive=7d use_temp_path=off;
            server {
              server_name "";
              listen ${var.nginx_port};
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
              if_modified_since off;
              add_header Last-Modified "";

              location / {
                proxy_pass http://frontend.virtual.global:${var.frontend_port};
                proxy_set_header  Host  frontend;
              }

              location ^~ /hashicups {
                rewrite ^/hashicups(.*)$ /$1 last;
              }

              location /static {
                #proxy_cache_valid 60m;
                proxy_pass http://frontend.virtual.global:${var.frontend_port};
                proxy_set_header  Host  frontend;
              }

              location /api {
                proxy_pass http://public-api.virtual.global:${var.public_api_port};
              }

              location  /health {
               access_log off;
               add_header 'Content-Type' 'application/json';
               return 200 '{"status":"UP"}';
              }
              error_page   500 502 503 504  /50x.html;
              location = /50x.html {
                root   /opt/bitnami/nginx/html;
              }
              
              
            }
        EOF
        destination = "local/nginx.conf"
      }
    }
  }
}