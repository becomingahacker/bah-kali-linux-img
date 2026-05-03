#!/bin/bash
# Creates GCE base image from Kali generic cloud image (README "GCE Base Kali Image").
# Runs in phases with reboots; state is stored in /root/.gce-base-phase.

set -e
set -x
env

# For troubleshooting, disable when not in use.  Serial console only.
echo 'root:CHANGEME' | /usr/sbin/chpasswd

PHASE_FILE=/root/.gce-base-phase
export DEBIAN_FRONTEND=noninteractive
export APT_OPTS="-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0"

phase() { echo "$1" > "$PHASE_FILE"; }
get_phase() { cat "$PHASE_FILE" 2>/dev/null || echo "0"; }

case "$(get_phase)" in
  0)
    echo "=== Phase 1: Disable cloud-init network, fix growroot, grub, install kernel ==="
    mkdir -p /etc/cloud/cloud.cfg.d
    printf '%s\n' 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99_disable_networking_config.cfg
    rm -f /etc/network/interfaces.d/50-cloud-init
    # Without cloud-init's rendered fragment, ifupdown has nothing for the GCE NIC and
    # networking.service fails; metadata then never resolves and cloud-init-network hangs.
    cat > /etc/network/interfaces.d/99-gce-primary-dhcp <<'IFACE_EOF'
# GCE virtio NIC — Kali generic cloud images typically expose this as eth0.
# If your VM only has ens4, change the iface name here (or add a second stanza).
auto eth0
iface eth0 inet dhcp
IFACE_EOF

    # Fix initramfs growroot (grep/sed/rm/awk in /bin for growpart)
    cat > /usr/share/initramfs-tools/hooks/growroot << 'GROWROOT_EOF'
#!/bin/sh

PREREQ=""

prereqs()
{
        echo "$PREREQ"
}

case $1 in
prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions

copy_exec /usr/bin/grep /bin
copy_exec /usr/bin/sed /bin
copy_exec /usr/bin/rm /bin
copy_exec /usr/bin/awk /bin

exit 0
GROWROOT_EOF
    chmod u+x /usr/share/initramfs-tools/hooks/growroot
    update-initramfs -u

    # Serial console for GRUB
    echo 'GRUB_TERMINAL_INPUT="serial console"' >> /etc/default/grub
    update-grub

    apt-get update
    apt-get install -y linux-image-amd64

    phase 1
    echo "Phase 1 done. Rebooting..."
    cloud-init clean -c all -r
    ;;
  1)
    echo "=== Phase 2: Remove cloud kernel ==="
    apt-get remove --purge -y linux-image-cloud-amd64 || true
    apt-get remove --purge -y linux-image-*-cloud-amd64 || true
    phase 2
    echo "Phase 2 done. Rebooting..."
    cloud-init clean -c all -r
    ;;
  2)
    echo "=== Phase 3: Final cleanup and shutdown ==="
    chsh -s /usr/bin/bash root
    rm -f /etc/hosts /etc/hostname
    cloud-init clean -l --machine-id -c all
    rm -f /root/.zsh_history /root/.bash_history
    history -c 2>/dev/null || true
    phase 3
    echo "Phase 3 done. Shutting down..."
    shutdown -P now
    ;;
  *)
    echo "Already at phase $(get_phase). Exiting."
    exit 0
    ;;
esac
