# Packer variables (all are required)
project                   = "GCP_PROJECT_ID"
region                    = "europe-west1"
zone                      = "europe-west1-b"

# Terraform variables (all are required)
retry_join                = "project_name=GCP_PROJECT_ID zone_pattern=europe-west1-b provider=gce tag_value=auto-join"
