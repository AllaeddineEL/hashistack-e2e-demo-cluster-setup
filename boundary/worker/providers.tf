data "terraform_remote_state" "boundary_cluster" {
  backend = "local"

  config = {
    path = "../cluster/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1.1.15"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.1"
    }
  }
}

provider "boundary" {
  addr                   = data.terraform_remote_state.boundary_cluster.outputs.boundary_url
  auth_method_id         = data.terraform_remote_state.boundary_cluster.outputs.boundary_admin_auth_method
  auth_method_login_name = "admin"
  auth_method_password   = data.terraform_remote_state.boundary_cluster.outputs.boundary_admin_password
}
