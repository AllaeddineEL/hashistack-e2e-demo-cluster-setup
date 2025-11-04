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

variable "nginx_port" {
  description = "Nginx Port"
  default = 80
}
variable "nomad_ns" {
  description = "The Namespace name to deploy the DB task"
  default = "frontend-team"
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
      mode = "host"
      port "nginx" {
        static = var.nginx_port
        to = var.nginx_port
      }
    }
    service {
        name = "nginx"
        provider = "consul"
        port = "nginx"
        check {
          name      = "NGINX ready"
					type      = "http"
          path			= "/health"
					interval  = "5s"
					timeout   = "5s"
        }
    }
    task "nginx" {
      driver = "docker"
      meta {
        service = "nginx-reverse-proxy"
      }
      config {
        image = "nginx:alpine"
        ports = ["nginx"]
        network_mode = "host"
        mount {
          type   = "bind"
          source = "local/nginx.conf"
          target = "/etc/nginx/conf.d/nginx.conf"
        }
      }
      template {
        data =  <<EOF
          server {
            server_name localhost;
            listen 80 default_server;

            proxy_http_version 1.1;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            proxy_temp_file_write_size 64k;
            proxy_connect_timeout 10080s;
            proxy_send_timeout 10080;
            proxy_read_timeout 10080;
            proxy_buffer_size 64k;
            proxy_buffers 16 32k;
            proxy_busy_buffers_size 64k;
            proxy_redirect off;
            proxy_request_buffering off;
            proxy_buffering off;

            location / {
            {{ range service "frontend" }}
              proxy_pass http://{{ .Address }}:{{ .Port }};{{- end }}
            }

            location /static {
              proxy_cache_valid 60m;
              {{ range service "frontend" }}
              proxy_pass http://{{ .Address }}:{{ .Port }};{{- end }}
            }

            location /api {
              {{ range service "public-api" }}
              proxy_pass http://{{ .Address }}:{{ .Port }};
              {{ end }}
            }
            location = /health {
              access_log off;
              add_header 'Content-Type' 'application/json';
              return 200 '{"status":"UP"}';
            }

            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
              root   /usr/share/nginx/html;
            }
          }
        EOF
        destination = "local/nginx.conf"
      }
    }
  }
}