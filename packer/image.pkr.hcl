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
  default = "packer$HashiStack"
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
  source_image = "windows-server-2019-dc-v20200813"
  zone         = var.zone
  disk_size    = 50
  machine_type = "n1-standard-2"
  communicator = "ssh"
  ssh_username = var.packer_username
  ssh_password = var.packer_user_password
  ssh_timeout  = "1h"
  metadata     = {
    sysprep-specialize-script-cmd = "net user ${var.packer_username} \"${var.packer_user_password}\" /add /y & wmic UserAccount where Name=\"${var.packer_username}\" set PasswordExpires=False & net localgroup administrators ${var.packer_username} /add & powershell Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 & powershell Start-Service sshd & powershell Set-Service -Name sshd -StartupType 'Automatic' & powershell New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Set-ExecutionPolicy -ExecutionPolicy bypass -Force\""
  }
}
hcp_packer_registry {
  bucket_name = "hashistack-demo"
  description = "HashiStack E2E Demo"
  bucket_labels = {
    "team" = "platform-engineering",
    "os"   = "ubuntu",
    "cloud" = "GCP"
  }
  build_labels = {
    "build-time"   = timestamp(),
    "build-source" = basename(path.cwd)
  }
}
build {
  sources = ["sources.googlecompute.hashistack"]


   provisioner "ansible" {
      playbook_file = "../shared/scripts/hashistack.yml"
      user          = "ubuntu"
      extra_arguments = [
        "--extra-vars", "cloud_env=gce","--become"
      ]

   }
     # Install mondoo
  provisioner "shell" {
    inline = [
      "sudo bash -c \"$(curl -sSL https://install.mondoo.com/sh)\""
    ]
  }

  # Run mondoo to generate the SBOM
  provisioner "shell" {
    inline = [
      "cnquery sbom --output cyclonedx-json --output-target /tmp/sbom_cyclonedx.json"
    ]
  }
    # Upload SBOM
  provisioner "hcp-sbom" {
    source      = "/tmp/sbom_cyclonedx.json"
    destination = "./sbom"
    sbom_name   = "sbom-cyclonedx-ubuntu"
  }

}

build {

  sources = ["sources.googlecompute.win-hashistack"]
  
  provisioner "powershell" {
    script = "../shared/scripts/install-hashistack.ps1"
    elevated_user     = var.packer_username
    elevated_password = var.packer_user_password
  }
  provisioner "file" {
    source = "../shared/conf/agent-config-consul_win_client.hcl"
    destination = "C:\consul\consul.hcl"
  }
   provisioner "file" {
    source = "../shared/conf/agent-config-nomad_win_client.hcl"
    destination = "C:\nomad\nomad.hcl"
  }

}  