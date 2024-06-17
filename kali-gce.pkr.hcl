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

  # TODO cmm - Disabled, as exporting is way too slow.  It mounts the disk as
  # a standard persistent disk, then exports it.
  # I'll just create an SSD disk by hand and import it directly from the controller.
  # Example:
  # root@cml-controller:/mnt/kali# qemu-img convert -O qcow2 -f raw /dev/sdc \
  #   /var/local/virl2/dropfolder/kali-linux-1718585372-cloud-cml-amd64.qcow2 
  ## Export to Google Cloud Storage
  #post-processor "googlecompute-export" {

  #  only = [ "googlecompute.kali-linux-cloud-cml-amd64" ]

  #  service_account_email = var.service_account_email

  #  paths = [
  #    "gs://bah-machine-images/kali-linux/kali-linux-{{timestamp}}-cloud-cml-amd64.tar.gz",
  #  ]

  #  # TODO cmm - This can be set to false when tweaking is complete
  #  keep_input_artifact = true
  #}

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