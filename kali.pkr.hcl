packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}


source "qemu" "kali-2024-2" {
  # https://kali.download/cloud-images/kali-2024.2/kali-linux-2024.2-cloud-genericcloud-amd64.tar.xz
  iso_url = "kali-linux-2024.2-cloud-genericcloud-amd64.raw"
  iso_checksum      = "sha1:9413b8a86cae97d07416f66e46edbf7dc6ad7189"
  disk_image       = true
  use_backing_file = false
  output_directory = "build"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  disk_size        = "20000M"
  format           = "qcow2"
  #accelerator      = "kvm"
  vm_name          = "kali-linux.qcow2"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  ssh_username     = "root"
  # ssh_password     = "toor"
  ssh_private_key_file = "secrets/bah_id_ed25519"
  boot_wait        = "20s"
  boot_command      = ["echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKFdBqJEGmhr4wMLh2LfDvk5YVy8gi0Tc9wU+jl7lYL >> /root/.ssh/authorized_keys<enter>"]
  headless = true
  vnc_port_min = 5901
  vnc_port_max = 5901
}

build {
  provisioner "shell" {
    inline = ["echo foo"]
  }
  sources = ["source.qemu.kali-2024-2"]
}