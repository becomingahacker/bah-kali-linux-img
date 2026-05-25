#!/bin/bash

# Setup script for Kali Linux
# This script is used to setup the Kali Linux image to make it suitable for the
# Becoming a Hacker Foundations labs and building a new pristine image.

set -euo pipefail
set -x

env

# Wait for possible auto updates to complete.  This may not be needed
flock -w 120 /var/lib/apt/lists/lock -c 'echo waiting for lock'

apt update
apt upgrade -y

# Set the locale to en_US.UTF-8
printf "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\n" > /etc/default/locale
apt install -y locales-all
locale-gen --purge "en_US.UTF-8"
dpkg-reconfigure locales

# Set the timezone to Eastern
timedatectl set-timezone America/New_York

# Permanently enable cloud-init
systemctl enable cloud-init.target

# Install Docker
# Add Docker's official GPG key:
sudo apt install -y ca-certificates curl gpg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's repository to Apt sources, but leave it disabled.
echo \
  Docker "Docker deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list~ > /dev/null

# Install gcloud SDK, including Kubernetes
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo \
  "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt \
  cloud-sdk main" | \
  tee /etc/apt/sources.list.d/google-cloud-sdk.list
apt update

# https://www.kali.org/docs/general-use/metapackages/
# Not including google-guest-agent on purpose
# Ignore errors; we will fix in the tweak cycle
# Install Docker, but not commmunity edition.
# Install tigervnc for remote desktop access with Guacamole.
apt install -y kali-desktop-xfce kali-linux-default pciutils lshw \
  lightdm usbutils beef-xss mtr cisco7crack \
  google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin \
  google-cloud-cli-kubectl-oidc kubectl \
  zenmap rdap systemd-timesyncd pulseaudio-utils \
  docker.io \
  tigervnc-standalone-server tigervnc-common || true

# Install tftpd-hpa for TFTP server
apt remove --purge -y atftpd || true
apt install -y tftpd-hpa
cat > /etc/default/tftpd-hpa <<EOF
# /etc/default/tftpd-hpa

TFTP_USERNAME="nobody"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure --create"

EOF

mkdir -vp /srv/tftp
chown -R nobody:nogroup /srv/tftp

systemctl enable --now tftpd-hpa.service

install -d -m 755 -o root -g root /etc/sslh

# Boot into multi-user.target
systemctl set-default multi-user.target
#systemctl enable lightdm.service

# Disable Bluetooth
systemctl disable blueman-mechanism.service

# Enable serial console on ttyS1.  ttyS0 logs in automatically as root.
systemctl enable --now 'getty@ttyS1'

# Don't display message when automatically logging in
touch /root/.hushlogin

#mkdir -vp /provision/websploit
#cd /provision/websploit
#git clone https://github.com/The-Art-of-Hacking/websploit.git
#cd websploit
#sed -i 's/print_banner/#print_banner/g' install.sh
#chmod u+x install.sh
## FIXME cmm - Temporarily disable websploit for troubleshooting
#./install.sh

## Copy provisioning for Becoming a Hacker Foundations labs
#chmod u+x /provision/becoming-a-hacker/becoming-a-hacker.sh
#/provision/becoming-a-hacker/becoming-a-hacker.sh

cat > /etc/cloud/clean.d/10-cml-clean <<EOF
#!/bin/sh -x

sudo rm /etc/hosts
sudo rm /etc/hostname

sudo rm /root/.zsh_history
sudo rm /root/.bash_history
# Remove Google Cloud SDK configs, including credentials.
sudo rm -rf /root/.config/gcloud || true
sudo truncate -s 0 /root/.ssh/authorized_keys

sudo userdel -f -r kali || true

# Clean up packages that can be removed
apt autoremove --purge -y
apt clean

EOF
chmod u+x /etc/cloud/clean.d/10-cml-clean
