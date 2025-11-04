output "boundary_admin_password" {
  description = "The Password for the Boundary admin user"
  value       = data.terraform_remote_state.boundary_cluster.outputs.boundary_admin_password
}

output "boundary_url" {
  description = "The public URL of the HCP Boundary Cluster"
  value       = data.terraform_remote_state.boundary_cluster.outputs.boundary_url
}
output "boundary_admin_username" {
  description = "The Username for the Boundary admin user"
  value       = "admin"
}
output "boundary_auth_method_id" {
  value = data.terraform_remote_state.boundary_cluster.outputs.boundary_admin_auth_method
}
output "vault_target_id" {
  value = boundary_target.vault.id
}
