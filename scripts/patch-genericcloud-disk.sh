#!/usr/bin/env bash
# Apply a local tree onto the root filesystem of a Kali generic cloud disk.raw
# before GCE import. Use this when you need to change files on the image without
# booting it.
#
# Layout: each top-level directory under the overlay is merged into the same path
# on the guest (e.g. overlay/etc/cloud/cloud.cfg.d/foo.cfg -> /etc/cloud/...).
#
# Usage:
#   ./scripts/patch-genericcloud-disk.sh /path/to/disk.raw [OVERLAY_DIR]
#
# Requires: apt-get install -y libguestfs-tools
#
# Cloud Build: install libguestfs-tools in the import step, then after extracting
# disk.raw call this script before gsutil cp. If libguestfs fails on the worker,
# try: export LIBGUESTFS_BACKEND=direct
#
# After copying the overlay, runs update-grub inside the guest so /boot/grub/grub.cfg
# matches /etc/default/grub.d (e.g. serial console). Set SKIP_UPDATE_GRUB=1 to skip.

set -euo pipefail

DISK="${1:?disk.raw path required}"
OVERLAY="${2:-${OVERLAY_DIR:-genericcloud-overlay}}"

if [[ ! -f "$DISK" ]]; then
  echo "error: disk image not found: $DISK" >&2
  exit 1
fi

if [[ ! -d "$OVERLAY" ]]; then
  echo "patch-genericcloud-disk: no overlay at $OVERLAY — skipping."
  exit 0
fi

if ! command -v virt-copy-in >/dev/null 2>&1; then
  echo "error: virt-copy-in not found; install libguestfs-tools" >&2
  exit 1
fi

shopt -s nullglob
entries=("$OVERLAY"/*)
if [[ ${#entries[@]} -eq 0 ]]; then
  echo "patch-genericcloud-disk: overlay empty — skipping."
  exit 0
fi

echo "Applying overlay $OVERLAY -> $DISK ..."
for entry in "${entries[@]}"; do
  name="$(basename "$entry")"
  # Merge top-level dirs (etc, boot, ...) onto guest /
  virt-copy-in -a "$DISK" "$entry" "/$name"
done

if [[ "${SKIP_UPDATE_GRUB:-0}" != "1" ]]; then
  if ! command -v virt-customize >/dev/null 2>&1; then
    echo "error: virt-customize not found; install libguestfs-tools" >&2
    exit 1
  fi
  echo "Running update-grub in guest (virt-customize) ..."
  virt-customize -a "$DISK" \
    --run-command 'DEBIAN_FRONTEND=noninteractive update-grub'
fi

echo "patch-genericcloud-disk: done."
