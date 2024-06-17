packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

variable "project_id" {
    type        = string
    default     = ""
    description = "Project ID, e.g. gcp-asigbahgcp-nprd-47930"
}

variable "zone" {
    type        = string
    default     = ""
    description = "Zone, e.g. us-east1-b."
}

variable "service_account_email" {
    type        = string
    default     = ""
    description = "Service account to use while building."
}

variable "source_image_family" {
    type        = string
    default     = "kali-linux-cloud-gce-amd64"
    description = "Parent image family, e.g. kali-linux-cloud-gce-amd64"
}

variable "provision_script" {
    type        = string
    default     = "setup.sh"
    description = "Provisioning script"
}

locals {
  ssh_public_key          = file("${path.root}/secrets/id_ed25519.pub")

  user_data = {
    users = [
      {
        name                = "root"
        lock_passwd         = true
        ssh_authorized_keys = [
          local.ssh_public_key,
        ]
      },
    ]
  }
}

source "googlecompute" "kali-linux-cloud-cml-amd64" {
  project_id              = var.project_id
  # Pristine image from base GCE image family
  source_image_family     = var.source_image_family
  # For tweaks to existing image we've already built
  #source_image_family     = "kali-linux-cloud-cml-amd64"
  image_family            = "kali-linux-cloud-cml-amd64"
  image_name              = "kali-linux-{{timestamp}}-cloud-cml-amd64"

  zone                    = var.zone
  machine_type            = "n2-highcpu-8"

  disk_size               = 48
  disk_type               = "pd-ssd"
  image_storage_locations = [
    "us-east1",
  ]

  ssh_username            = "root"
  ssh_private_key_file    = "secrets/id_ed25519"
  service_account_email   = var.service_account_email

  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]

  metadata = {
    user-data = format("#cloud-config\n%s", yamlencode(local.user_data))
  }
}

build {
  sources = ["sources.googlecompute.kali-linux-cloud-cml-amd64"]

  provisioner "shell" {
    only           = [
      "googlecompute.kali-linux-cloud-cml-amd64",
    ]

    script = var.provision_script

    environment_vars = [
      "APT_OPTS=\"-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0\"",
      "DEBIAN_FRONTEND=noninteractive",
    ]
  }

  post-processor "manifest" {
    only           = [
      "googlecompute.kali-linux-cloud-cml-amd64",
    ]
    output = "manifest.json"
    strip_path = true
    custom_data = {
      my_custom_data = "example"
    }
  }
}