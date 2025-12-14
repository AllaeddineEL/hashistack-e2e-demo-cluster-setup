packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.4"
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

source "googlecompute" "hashistack" {
  image_name   = "hashistack-${local.timestamp}"
  project_id   = var.project
  source_image = "ubuntu-minimal-2404-noble-amd64-v20241004"
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
  sources = ["sources.googlecompute.hashistack", "sources.googlecompute.win-hashistack"]

   #Provision the linux HashiStack image with Ansible
   provisioner "ansible" {
      only   = ["googlecompute.hashistack"]
      playbook_file = "../shared/scripts/hashistack.yml"
      user          = "ubuntu"
      extra_arguments = [
        "--extra-vars", "cloud_env=gce","--become"
      ]

   }
     # Install mondoo
  provisioner "shell" {
    only   = ["googlecompute.hashistack"]
    inline = [
      "sudo bash -c \"$(curl -sSL https://install.mondoo.com/sh)\""
    ]
  }

  # Run mondoo to generate the SBOM
  provisioner "shell" {
    only   = ["googlecompute.hashistack"]
    inline = [
      "cnquery sbom --output cyclonedx-json --output-target /tmp/sbom_cyclonedx.json"
    ]
  }
  # Upload Linux SBOM
  provisioner "hcp-sbom" {
    only   = ["googlecompute.hashistack"]
    source      = "/tmp/sbom_cyclonedx.json"
    destination = "./sbom"
    sbom_name   = "sbom-cyclonedx-ubuntu"
  }

  provisioner "powershell" {
    only   = ["googlecompute.win-hashistack"]
    script = "../shared/scripts/install-hashistack.ps1"
    elevated_user     = var.packer_username
    elevated_password = var.packer_user_password
  }
  provisioner "powershell" {
    only   = ["googlecompute.win-hashistack"]
    inline = [
      "Set-ExecutionPolicy Unrestricted -Scope Process -Force;", 
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1/cnquery'));",
      "Install-Mondoo -Product cnquery;"
    ]
    elevated_user     = var.packer_username
    elevated_password = var.packer_user_password
  }

  provisioner "powershell" {
    only   = ["googlecompute.win-hashistack"]
    inline = [
    "& \"C:\\Program Files\\Mondoo\\cnquery.exe\" sbom --output cyclonedx-json --output-target C:\\Windows\\Temp\\win_sbom_cyclonedx.json"
    ]
    elevated_user     = var.packer_username
    elevated_password = var.packer_user_password
  }
  provisioner "hcp-sbom" {
    only   = ["googlecompute.win-hashistack"]
    source      = "C:/Windows/Temp/win_sbom_cyclonedx.json"
    destination = "./win-sbom"
    sbom_name   = "sbom-cyclonedx-windows"
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