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

  ssh_username       = "root"
  # Must match secrets/id_ed25519.pub in cloud-init user-data below. Do not use
  # temporary_key_pair_type here: cloud-init replaces root's authorized_keys with
  # only the keys from user-data, which removes the guest-agent–injected temp key
  # and breaks SSH (Packer would still offer the temp private key).
  ssh_private_key_file = "${path.root}/secrets/id_ed25519"
  use_iap              = true
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
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} bash '{{ .Path }}'"
    inline = [ 
      "mkdir -vp /provision/websploit",
      "mkdir -vp /provision/becoming-a-hacker" 
    ]
  }

  # These are files copied here, rather than in the cloud-init because we don't
  # want to do any YAML encoding/processing on them.
  provisioner "file" {
    source      = "/workspace/scripts/setup.sh"
    destination = "/provision/setup.sh"
  }

  provisioner "file" {
    source      = "/workspace/scripts/tweaks.sh"
    destination = "/provision/tweaks.sh"
  }

  provisioner "file" {
    source      = "/workspace/scripts/becoming-a-hacker.sh"
    destination = "/provision/becoming-a-hacker/becoming-a-hacker.sh"
  }

  provisioner "file" {
    source      = "/workspace/files/custom-desktop.png"
    destination = "/provision/custom-desktop.png"
  }

  # Let cloud-init finish before running the
  # main provisioning script.  If cloud-init fails,
  # output the log and stop the build.
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} bash '{{ .Path }}'"
    inline = [ <<-EOF
      echo "waiting for cloud-init setup to finish..."
      cloud-init status --wait || true

      cloud_init_state="$(cloud-init status | awk '/status:/ { print $2 }')"

      if [ "$cloud_init_state" = "done" ]; then
        echo "cloud-init setup has successfully finished"
      else
        echo "cloud-init setup is in unknown state: $cloud_init_state"
        cloud-init status --long
        cat /var/log/cloud-init-output.log
        echo "stopping build..."
        exit 1
      fi
      
      echo "Starting main provisioning script..."
      chmod u+x /provision/${var.provision_script}
      /provision/${var.provision_script}
    EOF
    ]
    env = { 
      APT_OPTS         = "-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0"
      DEBIAN_FRONTEND  = "noninteractive"
    }
  }

  # Clean up all cloud-init data and shutdown cleanly.
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} bash '{{ .Path }}'"
    inline = [
      "cloud-init clean -c all -l --machine-id",
      "rm -rf /var/lib/cloud",
      "sync",
      "sync",
    ]
  }

  post-processor "manifest" {
    output = "/workspace/manifest.json"
    strip_path = true
    #custom_data = {
    #  foo = "bar"
    #}
  }
}