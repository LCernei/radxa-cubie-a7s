#!/usr/bin/env bash
# Write the prepared image to an SD card and read it back.
# Usage: sudo scripts/flash.sh /dev/sdX
set -euo pipefail

die() {
  echo "refusing: $*" >&2
  exit 1
}

root=$(cd "$(dirname "$0")/.." && pwd)
img=$root/images/cubie-a7s-r7.img
dev=${1:-}

if [ -z "$dev" ]; then
  echo "usage: sudo $0 /dev/<sd-card>" >&2
  lsblk -d -o NAME,SIZE,TRAN,RM,MODEL >&2
  exit 2
fi
dev=$(readlink -f "$dev")
[ -b "$dev" ] || die "$dev is not a block device"
[ "$(lsblk -dno TYPE "$dev")" = disk ] || die "$dev is not a whole disk"

# Only removable, USB or MMC disks of SD card size, never one holding the running system.
removable=$(lsblk -dno RM "$dev" | tr -d ' ')
transport=$(lsblk -dno TRAN "$dev" | tr -d ' ')
case "$dev" in
/dev/mmcblk*) ;;
*) [ "$removable" = 1 ] || [ "$transport" = usb ] || die "$dev is an internal disk" ;;
esac
size=$(lsblk -bdno SIZE "$dev" | tr -d ' ')
[ "$size" -gt 0 ] || die "$dev has no card in it"
[ "$size" -le $((260 * 1000 * 1000 * 1000)) ] || die "$dev is larger than 260 GB"
if lsblk -nro MOUNTPOINTS "$dev" | grep -qE '^(/|/boot.*|/nix.*|/home.*|\[SWAP\])$'; then
  die "$dev holds the running system"
fi

[ -f "$img" ] || die "no image, run scripts/prepare-image.sh first"
bytes=$(stat -c %s "$img")
[ "$size" -ge "$bytes" ] || die "$dev is smaller than the image"
[ "$(id -u)" = 0 ] || die "run with sudo"

(cd "$(dirname "$img")" && sha256sum -c "$(basename "$img").sha256")

lsblk -o NAME,SIZE,TRAN,MODEL,LABEL,MOUNTPOINTS "$dev"
echo "EVERYTHING on $dev will be erased. Make sure this is the new card, not the old one."
read -r -p "Type $dev to continue: " answer
[ "$answer" = "$dev" ] || die "not confirmed"

while read -r mountpoint; do
  if [ -n "$mountpoint" ]; then
    umount "$mountpoint"
  fi
done < <(lsblk -nro MOUNTPOINTS "$dev")

dd if="$img" of="$dev" bs=4M conv=fsync status=progress
blockdev --flushbufs "$dev"
echo "verifying..."
cmp -n "$bytes" "$img" "$dev"
sync
echo "done, the card can be removed"
