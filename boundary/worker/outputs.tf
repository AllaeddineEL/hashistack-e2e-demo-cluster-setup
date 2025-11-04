output "boundary_admin_password" {
  description = "The Password for the Boundary admin user"
  value       = data.terraform_remote_state.boundary_cluster.outputs.boundary_admin_password
}

output "boundary_url" {
  description = "The public URL of the HCP Boundary Cluster"
  value       = data.terraform_remote_state.boundary_cluster.outputs.boundary_url
}
