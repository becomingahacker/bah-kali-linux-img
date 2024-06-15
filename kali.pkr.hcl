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
  shutdown_command     = "shutdown -P now"
  disk_size            = "50G"
  format               = "qcow2"
  # Not available on Google Cloud Builder
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
  vnc_port_min         = 5901
  vnc_port_max         = 5901
}

build {
  provisioner "shell" {
    inline = [
      "set -x",
      "APT_OPTS=\"-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0\"",
      "DEBIAN_FRONTEND=noninteractive",
      "export APT_OPTS DEBIAN_FRONTEND",
      "dpkg --get-selections",
      "apt-get update",
      "apt-get upgrade -y",
      "printf \"LANG=en_US.UTF-8\\nLC_ALL=en_US.UTF-8\\n\" > /etc/default/locale",
      "cat /etc/default/locale",
      "apt-get install -y locales-all",
      "locale-gen --purge \"en_US.UTF-8\"",
      "dpkg-reconfigure locales",
      # HACK cmm - don"t update the kernel, because it currently breaks things,
      # "echo "linux-image-cloud-amd64 hold" | dpkg --set-selections",
      #"apt-get install -y linux-image-amd64",
      # https://www.kali.org/docs/general-use/metapackages/
      "apt-get install -y kali-desktop-xfce kali-linux-default pciutils",
      "systemctl disable blueman-mechanism.service",
      "dpkg-reconfigure xorg",
      "dpkg -l",
      "touch /root/.hushlogin",
      "truncate --size=0 /root/.ssh/authorized_keys",
    ]
  }
  sources = ["source.qemu.kali-linux"]
}