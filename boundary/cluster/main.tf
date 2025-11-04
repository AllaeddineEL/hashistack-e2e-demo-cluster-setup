resource "random_pet" "pet_name" {
}

resource "random_pet" "random_password" {
  length = 2
}

#Create New HCP Project for these resources
resource "hcp_project" "project" {
  name        = "instruqt-${random_pet.pet_name.id}"
  description = "Project Created by Instruqt Boundary Demo Lab"
}

#Create HCP Boundary Cluster
resource "hcp_boundary_cluster" "boundary" {
  project_id = hcp_project.project.resource_id
  cluster_id = "instruqt-${random_pet.pet_name.id}"
  username   = "admin"
  password   = random_pet.random_password.id
  tier       = "PLUS"
}
