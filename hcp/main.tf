
variable "hcp_proj_name" {
  default = ""
}


#Create New HCP Project for the demo resources
resource "hcp_project" "project" {
  name        = var.hcp_proj_name
  description = "Project Created by E2E Demo Lab"
}
