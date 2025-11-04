variable "project" {
  description = "The GCP project to use."
}

variable "region" {
  description = "The GCP region to deploy to."
}

variable "zone" {
  description = "The GCP zone to deploy to."
}


variable "name" {
  description = "Prefix used to name various infrastructure components. Alphanumeric characters only."
  default     = "nomad"
}

variable "retry_join" {
  description = "Used by Consul to automatically form a cluster."
  type        = string
}

variable "allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
  default     = "0.0.0.0/0"
}

variable "server_instance_type" {
  description = "The compute engine instance type to use for servers."
  default     = "e2-standard-2"
}

variable "client_instance_type" {
  description = "The compute engine instance type to use for clients."
  default     = "e2-standard-2"
}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "3"
}

variable "root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 20
}

#------------------------------------------------------------------------------#
# Cluster Related Variables
#------------------------------------------------------------------------------#

# Used to define Consul datacenter and Nomad region
variable "domain" {
  description = "Domain used to deploy Consul and Nomad and to generate TLS certificates."
  default     = "global"
}

# Used to define Consul and Nomad domain
variable "datacenter" {
  description = "Datacenter used to deploy Consul and Nomad and to generate TLS certificates."
  default     = "dc1"
}
