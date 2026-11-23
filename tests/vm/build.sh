#!/usr/bin/env bash
# Build images/vm/disk.img: the prepared r7 image plus Debian's arm64 kernel and modules.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
work=$root/images/vm
img=$root/images/cubie-a7s-r7.img
cloud_url=https://cloud.debian.org/images/cloud/trixie/latest
cloud=debian-13-nocloud-arm64.tar.xz
root_offset_mib=332 # partition 3 of the r7 image
root_size_mib=3717

[ -f "$img" ] || {
  echo "run scripts/prepare-image.sh first" >&2
  exit 1
}
mkdir -p "$work"
cd "$work"
rm -rf disk.img root.img cloud.img mods known

if [ ! -f "$cloud" ]; then
  curl -fL -o "$cloud" "$cloud_url/$cloud"
fi
curl -fsSL "$cloud_url/SHA512SUMS" | grep " $cloud\$" | sha512sum -c -
tar -xJf "$cloud" disk.raw

# The cloud image's root partition starts at 128 MiB.
dd if=disk.raw of=cloud.img bs=1M skip=128 count=2943 conv=sparse status=none
rm disk.raw
debug() { debugfs -R "$*" cloud.img 2>/dev/null; }
kernel=$(debug "ls -p /boot" | cut -d/ -f6 | sed -n 's/^vmlinuz-//p' | head -1)
debug "dump /boot/vmlinuz-$kernel vmlinuz"
debug "dump /boot/initrd.img-$kernel initrd"
mkdir mods
debug "rdump /usr/lib/modules/$kernel mods"

cp --sparse=always "$img" disk.img
dd if=disk.img of=root.img bs=1M skip=$root_offset_mib count=$root_size_mib conv=sparse status=none
{
  echo "mkdir /usr/lib/modules/$kernel"
  cd "mods/$kernel"
  find . -mindepth 1 -type d | sed 's#^\./##' | sort | sed "s#^#mkdir /usr/lib/modules/$kernel/#"
  find . -type f | sed 's#^\./##' | while read -r f; do
    echo "write $PWD/$f /usr/lib/modules/$kernel/$f"
  done
} >cmds
debugfs -w -f cmds root.img >/dev/null 2>&1
dd if=root.img of=disk.img bs=1M seek=$root_offset_mib conv=notrunc,sparse status=none
rm -rf root.img cloud.img mods cmds
truncate -s 12G disk.img
echo "ready: $work/disk.img (kernel $kernel)"
