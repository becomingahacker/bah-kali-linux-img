#!/bin/bash

# Tweaks script for Kali Linux
# This script is used to tweak the Kali Linux image to make it suitable for the
# Becoming a Hacker Foundations labs without rebuilding an entire new image.

set -euo pipefail
set -x

env

flock -w 120 /var/lib/apt/lists/lock -c 'echo waiting for lock'

apt-get update
apt-get upgrade -y
