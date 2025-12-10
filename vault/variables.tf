variable "project" {
  description = "The GCP project to use."
}

variable "region" {
  description = "The GCP region to deploy to."
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP zone to deploy to."
  default     = "europe-west1-b"
}


variable "name" {
  description = "Prefix used to name various infrastructure components. Alphanumeric characters only."
  default     = "nomad"
}

variable "vault_version" {
  description = "The version of Vault to deploy."
  default     = "1.21.1"
}
