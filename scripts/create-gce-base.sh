#!/bin/bash
# Creates GCE base image from Kali generic cloud image (README "GCE Base Kali Image").
# Runs in phases with reboots; state is stored in /root/.gce-base-phase.

set -euo pipefail
set -x

env

export DEBIAN_FRONTEND=noninteractive
export APT_OPTS="-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0"

PHASE_FILE="/root/.gce-base-phase"

phase() { echo "$1" > "$PHASE_FILE"; }
get_phase() { cat "$PHASE_FILE" 2>/dev/null || echo "0"; }

case "$(get_phase)" in
  0)

    # For troubleshooting, disable when not in use.  Serial console only.
    echo 'root:CHANGEME' | /usr/sbin/chpasswd

    apt update -y
    apt upgrade -y
    apt clean

    phase 1
    echo "Phase 1 done. Rebooting..."
    cloud-init clean -c all -r
    ;;
  1)
    echo "=== Phase 3: Final cleanup and shutdown ==="
    chsh -s /usr/bin/bash root
    rm -f /etc/hosts /etc/hostname
    cloud-init clean -l --machine-id -c all
    rm -f /root/.zsh_history /root/.bash_history
    history -c 2>/dev/null || true
    phase 2
    echo "Phase 1 done. Shutting down..."
    shutdown -P now
    ;;
  *)
    echo "Already at phase $(get_phase). Exiting."
    exit 0
    ;;
esac
