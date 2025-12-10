output "boundary_admin_password" {
  description = "The Password for the Boundary admin user"
  value       = random_pet.random_password.id
}

output "boundary_url" {
  description = "The public URL of the HCP Boundary Cluster"
  value       = hcp_boundary_cluster.boundary.cluster_url
}

output "boundary_admin_auth_method" {
  description = "The Auth Method ID of the default UserPass auth method in the Global scope"
  value       = jsondecode(data.http.boundary_cluster_auth_methods.response_body).items[0].id
}

output "hcp_project_id" {
  value = data.terraform_remote_state.hcp.outputs.hcp_project_id
}
output "cluster_id" {
  description = "The public URL of the HCP Boundary Cluster"
  value       = hcp_boundary_cluster.boundary.cluster_id
}
