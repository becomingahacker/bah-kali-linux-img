packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

locals {
  ssh_public_key = file("${path.root}/secrets/id_ed25519.pub")
}

source "qemu" "kali-linux" {
  # e.g. https://kali.download/cloud-images/kali-2024.2/kali-linux-2024.2-cloud-genericcloud-amd64.tar.xz
  iso_url              = "disk.raw"
  iso_checksum         = "sha1:9413b8a86cae97d07416f66e46edbf7dc6ad7189"
  disk_image           = true
  use_backing_file     = false
  output_directory     = "build"
  shutdown_command     = "echo 'Packer finished' | sudo -S shutdown -P now"
  disk_size            = "16G"
  format               = "qcow2"
  #accelerator         = "kvm"
  vm_name              = "kali-linux"
  net_device           = "virtio-net"
  disk_interface       = "virtio"
  ssh_username         = "root"
  # ssh_password       = "toor"
  ssh_private_key_file = "secrets/id_ed25519"
  boot_wait            = "90s"
  boot_command         = [
    "echo ${local.ssh_public_key} >> /root/.ssh/authorized_keys<enter>"
  ]
  headless             = true
}

build {
  provisioner "shell-local" {
    inline = [
      "echo shell-local"
    ]
  }

  provisioner "shell" {
    inline = [
      "dpkg -l",
      "truncate --size=0 /root/.ssh/authorized_keys",
    ]
  }
  sources = ["source.qemu.kali-linux"]
}