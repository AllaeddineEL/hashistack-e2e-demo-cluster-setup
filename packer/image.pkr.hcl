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

source "googlecompute" "hashistack" {
  image_name   = "hashistack-${local.timestamp}"
  project_id   = var.project
  source_image = "ubuntu-minimal-2404-noble-amd64-v20241004"
  ssh_username  = "ubuntu"
  zone         = var.zone
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
     # Install trivy
  provisioner "shell" {
    inline = [
      "sudo bash -c \"$(curl -sSL https://install.mondoo.com/sh)\""
    ]
  }

  # Run trivy to generate the SBOM
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