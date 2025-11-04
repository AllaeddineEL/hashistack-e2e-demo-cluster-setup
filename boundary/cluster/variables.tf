variable "boundary_user" {
  type    = string
  default = "admin"
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "The GCP region"
}
variable "boundary_version" {
  default = "0.17.1"
}
