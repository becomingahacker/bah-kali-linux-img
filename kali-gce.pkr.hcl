packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

# variables.pkr.hcl
variable "service_account_email" {
    type        = string
    default     = "cisco-modeling-labs@gcp-asigbahgcp-nprd-47930.iam.gserviceaccount.com"
    description = "Service account to use while building."
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
  project_id              = "gcp-asigbahgcp-nprd-47930"
  # Pristine image from base GCE image family
  source_image_family     = "kali-linux-cloud-gce-amd64"
  # For tweaks to existing image we've already built
  #source_image_family     = "kali-linux-cloud-cml-amd64"
  image_family            = "kali-linux-cloud-cml-amd64"
  image_name              = "kali-linux-{{timestamp}}-cloud-cml-amd64"

  zone                    = "us-east1-b"
  machine_type            = "n2-standard-4"

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

    # Pristine
    script = "setup.sh"
    # Tweaks
    #script = "tweaks.sh"

    environment_vars = [
      "APT_OPTS=\"-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0\"",
      "DEBIAN_FRONTEND=noninteractive",
    ]
  }

  # Export to Google Cloud Storage
  post-processor "googlecompute-export" {
    only           = [
      "googlecompute.kali-linux-cloud-cml-amd64",
    ]
    service_account_email = var.service_account_email

    paths = [
      "gs://bah-machine-images/kali-linux/kali-linux-{{timestamp}}-cloud-cml-amd64.tar.gz",
    ]

    # TODO cmm - This can be set to false when tweaking is complete
    keep_input_artifact = true
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