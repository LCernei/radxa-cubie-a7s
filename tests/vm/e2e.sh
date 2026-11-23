#!/usr/bin/env bash
# End-to-end test of ansible/ in the VM. Starts and stops the VM itself.
#
#   e2e.sh                     fresh disk from build.sh: first boot, then as below; saves the
#                              snapshots "firstboot" and "configured" (~60 min)
#   e2e.sh --from firstboot    skip the first boot (~50 min)
#   e2e.sh --from configured   start from the last good full run: only changed roles do work
#                              (~15 min); keeps the snapshot as it was
#
# Each run: site.yml -> site.yml again (must report changed=0) -> reboot -> verify.yml.
# On failure the VM is left running for a look: ssh -p 2222 radxa@127.0.0.1
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
work=$root/images/vm
disk=$work/disk.qcow2
known=$work/known
from=
case "${1:-}" in
--from) from=${2:?firstboot or configured} ;;
"") ;;
*)
  sed -n '2,12p' "$0" >&2
  exit 2
  ;;
esac

# Throwaway VM: host keys change during first boot, and the default password is public.
opts=(-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 2222)
step() { echo "== $* ($(date +%T))"; }
vm() { ssh -o UserKnownHostsFile="$known" -o LogLevel=ERROR -o BatchMode=yes -o ConnectTimeout=20 -p 2222 radxa@127.0.0.1 "$@"; }
play() {
  (cd "$root/ansible" && ANSIBLE_BECOME_ASK_PASS=false ansible-playbook "$@" \
    -e ansible_host=127.0.0.1 -e ansible_port=2222 -e ansible_become_password=radxa \
    -e "ansible_ssh_common_args='-o UserKnownHostsFile=$known'")
}
changed() { grep -oE 'changed=[0-9]+' | tail -1; }

qemu_pid=
start() {
  "$root/tests/vm/run.sh" &
  qemu_pid=$!
}
wait_ssh() { until vm true 2>/dev/null; do sleep 15; done; }
stop() {
  vm 'echo radxa | sudo -S -p "" systemctl poweroff' || true
  wait "$qemu_pid" || true
}
# Internal qcow2 snapshots; the VM must be off.
save() {
  qemu-img snapshot -d "$1" "$disk" 2>/dev/null || true
  qemu-img snapshot -c "$1" "$disk"
}

[ -f "$disk" ] || {
  echo "run tests/vm/build.sh first" >&2
  exit 1
}
if ss -Htln 'sport = :2222' | grep -q .; then
  echo "port 2222 is in use: another VM is running, stop it first" >&2
  exit 1
fi

if [ -n "$from" ]; then
  step "restoring snapshot $from"
  qemu-img snapshot -a "$from" "$disk"
  start
  wait_ssh
else
  start
  step "waiting for the first boot"
  until [ -n "$(ssh-keyscan -T 5 -p 2222 127.0.0.1 2>/dev/null)" ]; do sleep 10; done
  until sshpass -p radxa ssh "${opts[@]}" -o PubkeyAuthentication=no radxa@127.0.0.1 \
    "echo radxa | sudo -S -p '' test ! -e /config/before.txt" 2>/dev/null; do sleep 20; done
  ssh-keyscan -T 15 -p 2222 127.0.0.1 >"$known" 2>/dev/null
  sshpass -p radxa ssh "${opts[@]}" -o PubkeyAuthentication=no radxa@127.0.0.1 \
    'mkdir -p -m 700 ~/.ssh && cat >>~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys' \
    <"${SSH_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
  vm 'getent passwd rock && exit 1; systemctl is-enabled ssh;
      echo radxa | sudo -S -p "" sh -c "growpart /dev/vda 3 && resize2fs /dev/vda3" >/dev/null'
  stop
  save firstboot
  start
  wait_ssh
fi

ok() { grep -qE 'unreachable=0 +failed=0' "$1" || {
  echo "failed: see $1" >&2
  exit 1
}; }
step "site.yml: $(play site.yml | tee "$work/run1.log" | changed)"
ok "$work/run1.log"
# A second run that changes nothing is the idempotency test; a --check run would add nothing.
step "site.yml again: $(play site.yml --diff | tee "$work/run2.log" | changed)"
ok "$work/run2.log"
grep -q 'changed=0' "$work/run2.log"

step reboot
stop
start
wait_ssh
play verify.yml | tee "$work/verify.log" | sed -n '/stdout_lines/,/]/p'
stop
if [ "$from" != configured ]; then
  save configured
  step "saved snapshot configured"
fi
step passed
