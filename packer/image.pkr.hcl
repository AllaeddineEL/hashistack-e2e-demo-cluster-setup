packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "project" {
  type = string
}

variable "zone" {
  type = string
}

variable "packer_username" {
  type = string
  default = "packer"
}
variable "packer_user_password" {
  type = string
  default = "Hash!5tack"
}

data "googlecompute-image" "hashistack" {
  project_id = "ubuntu-os-cloud"
  filters = "family=ubuntu-minimal-2404-lts-amd64 AND labels.public-image=true"
  most_recent = true
}

source "googlecompute" "hashistack" {
  image_name   = "hashistack-${local.timestamp}"
  project_id   = var.project
  source_image = data.googlecompute-image.hashistack.name #"ubuntu-minimal-2404-noble-amd64-v20241004"
  ssh_username = "ubuntu"
  zone         = var.zone
}

source "googlecompute" "win-hashistack" {
  image_name   = "win-hashistack-${local.timestamp}"
  project_id   = var.project
  source_image = "windows-server-2025-dc-v20251112"
  zone         = var.zone
  disk_size    = 50
  machine_type = "n1-standard-4"
  communicator = "ssh"
  ssh_username = var.packer_username
  ssh_password = var.packer_user_password
  ssh_timeout  = "1h"
  metadata     = {
    sysprep-specialize-script-cmd = "net user ${var.packer_username} ${var.packer_user_password} /ADD /passwordchg:no /expires:never /active:yes /fullname:\"${var.packer_username} User\" /y & net localgroup Administrators ${var.packer_username} /ADD & powershell Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Profile Any & powershell Start-Service sshd & powershell Set-Service -Name sshd -StartupType 'Automatic' & powershell -NoProfile -ExecutionPolicy Bypass -Command \"Set-ExecutionPolicy -ExecutionPolicy bypass -Force\""
  }
}

hcp_packer_registry {
  bucket_name = "hashistack-demo"
  description = "HashiStack E2E Demo"
  bucket_labels = {
    "team" = "platform-engineering",
    "cloud" = "GCP"
  }
  build_labels = {
    "build-time"   = timestamp(),
    "build-source" = basename(path.cwd)
  }
}

build {
  sources = ["sources.googlecompute.win-hashistack", "sources.googlecompute.hashistack"]
   
  
  provisioner "file" {
    only   = ["googlecompute.hashistack"]
    destination = "/tmp/"
    source      = "../shared"
  }
  provisioner "shell" {
    only   = ["googlecompute.hashistack"]
    inline = [
      "sudo mkdir -p /ops/shared",
      "sudo cp -R /tmp/shared /ops/"
    #  "cnspec sbom --output cyclonedx-json --output-target /tmp/sbom_cyclonedx.json"
    ]
  }
   #Provision the linux HashiStack image with Ansible
   provisioner "ansible" {
      only   = ["googlecompute.hashistack"]
      playbook_file = "../shared/scripts/hashistack.yml"
      user          = "ubuntu"
      extra_arguments = [
        "--extra-vars", "cloud_env=gce","--become", "-v" 
      ]
   }

  # Copy the WinSW configuration file to the Windows HashiStack image

  provisioner "powershell" {
    only   = ["googlecompute.win-hashistack"]
    inline = [
      "mkdir \"C:\\coredns\""
    ]
    elevated_user     = var.packer_username
    elevated_password = var.packer_user_password
  }
  provisioner "file" {
    only   = ["googlecompute.win-hashistack"]
    source = "../shared/conf/WinSW-CoreDNS.xml"
    destination = "C:/coredns/WinCoreDNS.xml"
  }
   provisioner "file" {
    only   = ["googlecompute.win-hashistack"]
    source = "../shared/conf/agent-config-coredns_win_client"
    destination = "C:/coredns/Corefile"
  }

  provisioner "powershell" {
    only   = ["googlecompute.win-hashistack"]
    script = "../shared/scripts/install-hashistack.ps1"
    elevated_user     = var.packer_username
    elevated_password = var.packer_user_password
  }
  # Upload Linux SBOM
  provisioner "hcp-sbom" {
  only   = ["googlecompute.hashistack"]  
  auto_generate = true
  destination = "./sbom/sbom_cyclonedx.json"
  sbom_name     = "auto-generated-sbom"
}
  provisioner "file" {
    only   = ["googlecompute.win-hashistack"]
    source = "../shared/conf/agent-config-consul_win_client.hcl"
    destination = "C:/consul/config/consul.hcl"
  }
   provisioner "file" {
    only   = ["googlecompute.win-hashistack"]
    source = "../shared/conf/agent-config-nomad_win_client.hcl"
    destination = "C:/nomad/config/nomad.hcl"
  }

}