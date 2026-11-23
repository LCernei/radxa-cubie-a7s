#!/usr/bin/env bash
# Compare what the board runs, what Ansible pins, and what upstream has released.
# Read-only: it only reads upstream pages and, over SSH, installed versions.
# Exit status 1 when something is older than upstream or the board differs from the pin.
#
#   scripts/check-versions.sh                 # board over mDNS
#   scripts/check-versions.sh --no-board      # pins vs upstream only
#   BOARD=radxa@192.168.1.20 scripts/check-versions.sh
#
# Needs curl, jq, yq. Set GITHUB_TOKEN if GitHub's anonymous rate limit (60/h) bites.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
vars=$root/ansible/group_vars/print_server.yml
board=${BOARD:-radxa@radxa-cubie-a7s.local}
[ "${1:-}" = --no-board ] && board=

# Canon keeps one Asia page for the UFR II Linux driver and updates it in place (it showed V6.30
# before V6.40). Its download link is a redirect to the real archive on gdlp01.c-wss.com.
canon_page=https://asia.canon/en/support/0100924010

pin() { yq -r ".$1" "$vars"; }
gh_latest() {
  curl -fsS ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$1/releases/latest" | jq -r '.tag_name | ltrimstr("v")'
}
canon_latest() {
  local html id
  html=$(curl -fsSL -A 'Mozilla/5.0' "$canon_page")
  id=$(grep -oE 'WWUFORedirectTarget\.do\?id=[A-Za-z0-9=]+' <<<"$html" | head -1 | cut -d= -f2-)
  [ -n "$id" ] || return 1
  # The archive name, e.g. linux-UFRII-drv-v640-m17n-10.tar.gz, holds version and build.
  curl -fsS -o /dev/null -A 'Mozilla/5.0' -w '%{redirect_url}' \
    "https://pdisp01.c-wss.com/gdl/WWUFORedirectTarget.do?id=$id&cmp=ACB&lang=EN"
}
# linux-UFRII-drv-v640-m17n-10.tar.gz -> 6.40-1.10 (the .deb version inside)
canon_version() { sed -nE 's/.*-v([0-9])([0-9]+)-m17n-([0-9]+)\.tar\.gz$/\1.\2-1.\3/p' <<<"$1"; }

if [ -n "$board" ]; then
  installed=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$board" '
    dpkg-query -W -f="\${Version}\n" scanservjs 2>/dev/null | sed "s/-[^-]*$//" || echo none
    cat /usr/local/share/airsane/version 2>/dev/null || echo none
    dpkg-query -W -f="\${Version}\n" cnrdrvcups-ufr2-uk 2>/dev/null || echo none
    apt list --upgradable 2>/dev/null | grep -c / || true
  ') || {
    echo "board $board not reachable (mDNS fails sometimes: retry, or BOARD=radxa@<ip>)" >&2
    exit 2
  }
  mapfile -t inst <<<"$installed"
else
  inst=(- - - -)
fi

canon_url=$(canon_latest) || canon_url=
canon_new=$(canon_version "$canon_url")

status=0
row() { # name board pinned latest
  local note=ok
  if [ "$4" = "?" ]; then
    note="upstream unknown"
    status=1
  elif [ "$3" != "$4" ]; then
    note="update available"
    status=1
  fi
  if [ "$2" = none ]; then
    note="not on the board; $note"
    status=1
  elif [ "$2" != - ] && [ "$2" != "$3" ]; then
    note="board differs from pin (run site.yml); $note"
    status=1
  fi
  printf '%-12s %-12s %-12s %-12s %s\n' "$1" "$2" "$3" "$4" "$note"
}

printf '%-12s %-12s %-12s %-12s %s\n' component board pinned latest status
row scanservjs "${inst[0]}" "$(pin scanning_version)" "$(gh_latest sbs20/scanservjs || echo '?')"
row airsane "${inst[1]}" "$(pin airsane_version)" "$(gh_latest SimulPiscator/AirSane || echo '?')"
row canon "${inst[2]}" "$(pin printing_canon_version)" "${canon_new:-?}"

[ "$(pin printing_canon_version)" != "$canon_new" ] && [ -n "$canon_url" ] &&
  echo "canon: newest archive is $canon_url (pin its sha256 after reading it, docs/decisions/0003)"
[ "${inst[3]}" != - ] &&
  echo "debian: ${inst[3]} upgradable package(s) on the board, held board packages included (ansible-playbook update.yml)"
[ -z "$canon_url" ] && echo "canon: could not read $canon_page (page layout changed?)" >&2
exit $status
