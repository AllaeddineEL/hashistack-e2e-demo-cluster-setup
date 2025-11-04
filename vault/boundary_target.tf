
##### Dev Org Resources #####

# Create Organization Scope for Securirty Team
resource "boundary_scope" "sec_org" {
  scope_id                 = "global"
  name                     = "sec_ops_org"
  description              = "Security Oerations Org"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

# Create Project for the shared services resources
resource "boundary_scope" "shared_svc_project" {
  name                     = "shared_svc_project"
  description              = "Shared services Project"
  scope_id                 = boundary_scope.sec_org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}


resource "boundary_target" "vault" {
  type                     = "tcp"
  name                     = "vault"
  description              = "Connect to the Vault server"
  scope_id                 = boundary_scope.shared_svc_project.id
  session_connection_limit = -1
  default_port             = 8200
  address                  = "vault.service.dc1.global"
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
}
