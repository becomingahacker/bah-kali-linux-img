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
# After copying the overlay, sets root password to CHANGEME (lab default; change after
# boot) and runs update-grub inside the guest so /boot/grub/grub.cfg matches
# /etc/default/grub.d (e.g. serial console). Set SKIP_UPDATE_GRUB=1 to skip grub only.

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
# virt-copy-in places each *source* path's basename under the destination (like cp -r).
# Copying host .../overlay/etc into guest /etc would create /etc/etc/..., not merge.
# So copy each immediate child of overlay/<name>/ into guest /<name>/.
for entry in "${entries[@]}"; do
  name="$(basename "$entry")"
  if [[ -d "$entry" ]]; then
    shopt -s dotglob
    for child in "$entry"/*; do
      [[ -e "$child" ]] || continue
      virt-copy-in -a "$DISK" "$child" "/$name"
    done
    shopt -u dotglob
  else
    virt-copy-in -a "$DISK" "$entry" "/"
  fi
done

if ! command -v virt-customize >/dev/null 2>&1; then
  echo "error: virt-customize not found; install libguestfs-tools" >&2
  exit 1
fi

echo "Setting root password and guest post-overlay tasks (virt-customize) ..."
virt_args=(-a "$DISK" --root-password password:CHANGEME)
if [[ "${SKIP_UPDATE_GRUB:-0}" != "1" ]]; then
  virt_args+=(--run-command 'DEBIAN_FRONTEND=noninteractive update-grub')
fi
virt-customize "${virt_args[@]}"

echo "patch-genericcloud-disk: done."
