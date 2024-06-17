#!/bin/bash

set -e
set -x

env

# HACK cmm - Disable security.ubuntu.com so we don't get throttled
#sed -i 's@deb http://security.ubuntu.com@# deb http://security.ubuntu.com@' /etc/apt/sources.list
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

# Make network timeout shorter to speed up boot if the network is unavailable
mkdir -p /etc/systemd/system/networking.service.d/
echo -e \"[Service]\nTimeoutStartSec=20sec\" > /etc/systemd/system/networking.service.d/timeout.conf
touch /root/.hushlogin

cat > /etc/cloud/clean.d/10-cml-clean <<EOF
#!/bin/sh -x

sudo rm /etc/hosts
sudo rm /etc/hostname

sudo rm /root/.zsh_history
sudo rm /root/.bash_history
sudo truncate -s 0 /root/.ssh/authorized_keys

# Clean up packages that can be removed
apt-get autoremove --purge -y
apt-get clean

EOF
chmod u+x /etc/cloud/clean.d/10-cml-clean

cloud-init clean -c all -l --machine-id
