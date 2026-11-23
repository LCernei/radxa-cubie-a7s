#!/usr/bin/env bash
# Build the image to flash: verified Radxa release + two first-boot fixes.
#   - SSH also starts when a display is attached
#   - the second sudo user (rock/rock) is never created
# Needs no root. Run inside the dev shell (mtools, xz).
set -euo pipefail

release=rsdk-r7
name=radxa-a733_trixie_cli_r7.output_512.img.xz
sha256=0d10d845dcda6c9e5070ef10ecf6ffba42bf9109add702c1307808dbf3f60b83
config_offset=16M # partition 1 of this release

root=$(cd "$(dirname "$0")/.." && pwd)
src=$root/images/r7/$name
out=$root/images/cubie-a7s-r7.img
url=https://github.com/radxa-build/radxa-a733/releases/download/$release/$name

mkdir -p "$(dirname "$src")"
[ -f "$src" ] || curl -fL --retry 4 -o "$src" "$url"
echo "$sha256  $src" | sha256sum -c -

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

rm -f "$out" "$out.sha256"
xz -T0 -dc "$src" | dd of="$out" bs=4M iflag=fullblock conv=sparse status=none

fat="$out@@$config_offset"
mcopy -n -i "$fat" ::before.txt "$tmp/stock"
sed -e 's/^if headless enable_service ssh$/enable_service ssh/' \
  -e '/^add_user rock rock$/d' \
  -e '/^user_append_group rock /d' \
  "$tmp/stock" >"$tmp/before.txt"

grep -qx 'enable_service ssh' "$tmp/before.txt"
if grep -qE '^(add_user|user_append_group) rock' "$tmp/before.txt"; then
  echo "rock user still in before.txt" >&2
  exit 1
fi
mcopy -o -i "$fat" "$tmp/before.txt" ::before.txt

echo "first-boot changes:"
diff "$tmp/stock" "$tmp/before.txt" || true
(cd "$(dirname "$out")" && sha256sum "$(basename "$out")" >"$(basename "$out").sha256")
echo "ready: $out"
