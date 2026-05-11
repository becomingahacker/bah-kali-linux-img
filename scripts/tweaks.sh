#!/bin/bash

# Tweaks script for Kali Linux
# This script is used to tweak the Kali Linux image to make it suitable for the
# Becoming a Hacker Foundations labs without rebuilding an entire new image.

set -euo pipefail
set -x

env

flock -w 120 /var/lib/apt/lists/lock -c 'echo waiting for lock'

apt update
apt upgrade -y

apt install -y \
    systemd-timesyncd \
    pulseaudio-utils 

# Boot into multi-user.target
systemctl set-default multi-user.target
systemctl disable lightdm.service
