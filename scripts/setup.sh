#!/bin/bash

# Setup script for Kali Linux
# This script is used to setup the Kali Linux image to make it suitable for the
# Becoming a Hacker Foundations labs and building a new pristine image.

set -e
set -x
env

# Wait for possible auto updates to complete.  This may not be needed
flock -w 120 /var/lib/apt/lists/lock -c 'echo waiting for lock'

apt-get update
apt-get upgrade -y

# Set the locale to en_US.UTF-8
printf "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\n" > /etc/default/locale
apt-get install -y locales-all
locale-gen --purge "en_US.UTF-8"
dpkg-reconfigure locales

# Set the timezone to Eastern
timedatectl set-timezone America/New_York

# https://www.kali.org/docs/general-use/metapackages/
# Not including google-guest-agent on purpose
# Ignore errors; we will fix in the tweak cycle
apt-get install -y kali-desktop-xfce kali-linux-default pciutils lshw usbutils beef-xss mtr || true

# Disable Bluetooth
systemctl disable blueman-mechanism.service

# Enable serial console on ttyS1
systemctl enable --now 'getty@ttyS1'

# Install Docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's repository to Apt sources, but leave it disabled.
echo \
  Docker "Docker deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list~ > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Install gcloud SDK, including Kubernetes
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo \
  "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt \
  cloud-sdk main" | \
  tee /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin google-cloud-cli-kubectl-oidc kubectl

apt-get install -y zenmap rdap 

# Install tftpd-hpa for TFTP server
apt remove --purge -y atftpd || true
apt-get install -y tftpd-hpa
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

# Enable serial console on ttyS1
systemctl enable --now 'getty@ttyS1'

# growroot in initramfs needs growpart (this hook copy_exec's it; package must be present at update-initramfs)
apt-get install -y cloud-guest-utils

# Don't display message when automatically logging in
touch /root/.hushlogin

# Ensure cisco user exists with a proper home directory so X/lightdm and
# gnome-keyring can write .Xauthority and ~/.local/share/keyrings.
if ! getent passwd cisco >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G users,adm,sudo cisco
fi
if [ -d /home/cisco ]; then
  chown -R cisco:cisco /home/cisco
  chmod 755 /home/cisco
fi
# Lock until deploy-time cloud-init sets password (e.g. CML node-definition)
passwd -l cisco 2>/dev/null || true

mkdir -vp /provision/websploit
cd /provision/websploit
git clone https://github.com/The-Art-of-Hacking/websploit.git
cd websploit
sed -i 's/print_banner/#print_banner/g' install.sh
chmod u+x install.sh
# FIXME cmm - Temporarily disable websploit for troubleshooting
#./install.sh

chmod u+x /provision/becoming-a-hacker/becoming-a-hacker.sh
/provision/becoming-a-hacker/becoming-a-hacker.sh

cat > /etc/cloud/clean.d/10-cml-clean <<EOF
#!/bin/sh -x

sudo rm /etc/hosts
sudo rm /etc/hostname

sudo rm /root/.zsh_history
sudo rm /root/.bash_history
sudo truncate -s 0 /root/.ssh/authorized_keys

sudo userdel -f -r kali || true

# Clean up packages that can be removed
apt-get autoremove --purge -y
apt-get clean

EOF
chmod u+x /etc/cloud/clean.d/10-cml-clean
