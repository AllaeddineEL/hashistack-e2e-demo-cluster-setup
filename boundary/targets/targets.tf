#Create Policy for Boundary to manage it's own token to Vault
data "vault_policy_document" "boundary-token-policy" {
  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read"]
  }
  rule {
    path         = "auth/token/renew-self"
    capabilities = ["update"]
  }
  rule {
    path         = "auth/token/revoke-self"
    capabilities = ["update"]
  }
  rule {
    path         = "sys/leases/renew"
    capabilities = ["update"]
  }
  rule {
    path         = "sys/leases/revoke"
    capabilities = ["update"]
  }
  rule {
    path         = "sys/capabilities-self"
    capabilities = ["update"]
  }
}

# Create Policy to read Dynamic DB secrets
data "vault_policy_document" "db-secrets" {
  rule {
    path         = "database/creds/product-api-db-owner"
    capabilities = ["read"]
  }
}

resource "vault_policy" "boundary-token-policy-dev" {
  name   = "boundary-token"
  policy = data.vault_policy_document.boundary-token-policy.hcl
}

resource "vault_policy" "db-policy" {
  name   = "db-policy"
  policy = data.vault_policy_document.db-secrets.hcl
}

resource "vault_token_auth_backend_role" "boundary-token-role-dev" {
  role_name        = "boundary-controller-role-dev"
  allowed_policies = [vault_policy.boundary-token-policy-dev.name, vault_policy.db-policy.name]
  orphan           = true
}

resource "vault_token" "boundary-token-dev" {
  role_name = vault_token_auth_backend_role.boundary-token-role-dev.role_name
  policies  = [vault_policy.boundary-token-policy-dev.name, vault_policy.db-policy.name]
  no_parent = true
  renewable = true
  ttl       = "24h"
  period    = "20m"
}

##### Dev Org Resources #####

# Create Organization Scope for Dev
resource "boundary_scope" "dev_org" {
  scope_id                 = "global"
  name                     = "dev_org"
  description              = "Dev Org"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

# Create Project for Dev AWS resources
resource "boundary_scope" "dev_project" {
  name                     = "dev_project"
  description              = "Dev Project"
  scope_id                 = boundary_scope.dev_org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# Create Postgres RDS Target
resource "boundary_target" "dev-db-target" {
  type                     = "tcp"
  name                     = "dev-db-target"
  description              = "Connect to the postgres database with Vault DB secrets engine credentials"
  scope_id                 = boundary_scope.dev_project.id
  session_connection_limit = -1
  default_port             = 5432
  address                  = "product-api-db.service.dc1.global"
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""

  brokered_credential_source_ids = [
    boundary_credential_library_vault.database.id
  ]
}

# Create Dev Vault Credential store
resource "boundary_credential_store_vault" "dev_vault" {
  name          = "dev_vault"
  description   = "Dev Vault Credential Store"
  address       = "http://vault.service.dc1.global:8200"
  token         = vault_token.boundary-token-dev.client_token
  scope_id      = boundary_scope.dev_project.id
  worker_filter = "\"${var.region}\" in \"/tags/region\""
}

# Create Database Credential Library
resource "boundary_credential_library_vault" "database" {
  name                = "database"
  description         = "Postgres DB Credential Library"
  credential_store_id = boundary_credential_store_vault.dev_vault.id
  path                = "database/creds/product-api-db-owner" # change to Vault backend path
  http_method         = "GET"
  credential_type     = "username_password"
}

resource "boundary_target" "hashicups" {
  type                     = "tcp"
  name                     = "hashicups"
  description              = "Connect to the HashiCups Demo App"
  scope_id                 = boundary_scope.dev_project.id
  session_connection_limit = -1
  default_port             = 80
  address                  = "nginx.service.dc1.global"
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
}

resource "boundary_target" "frontend" {
  type                     = "tcp"
  name                     = "frontend"
  description              = "Connect to the frontend App"
  scope_id                 = boundary_scope.dev_project.id
  session_connection_limit = -1
  default_port             = 3000
  address                  = "frontend.service.dc1.global"
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
}
