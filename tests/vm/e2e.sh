#!/usr/bin/env bash
# First boot -> site.yml -> site.yml (must not change) -> --check -> reboot -> verify.yml
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
work=$root/images/vm
known=$work/known
# Throwaway VM: host keys change during first boot, and the default password is public.
opts=(-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 2222)
step() { echo "== $* ($(date +%T))"; }
vm() { ssh -o UserKnownHostsFile="$known" -o LogLevel=ERROR -o BatchMode=yes -p 2222 radxa@127.0.0.1 "$@"; }
play() {
  (cd "$root/ansible" && ANSIBLE_BECOME_ASK_PASS=false ansible-playbook "$@" \
    -e ansible_host=127.0.0.1 -e ansible_port=2222 -e ansible_become_password=radxa \
    -e "ansible_ssh_common_args='-o UserKnownHostsFile=$known'")
}
changed() { grep -oE 'changed=[0-9]+' | tail -1; }

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

step "site.yml on the fresh image"
play site.yml >"$work/run1.log"
step "site.yml again: $(play site.yml | tee "$work/run2.log" | changed)"
step "--check: $(play site.yml --check --diff | tee "$work/run3.log" | changed)"
grep -q 'changed=0' "$work/run2.log" && grep -q 'changed=0' "$work/run3.log"

step reboot
vm 'echo radxa | sudo -S -p "" systemctl reboot' || true
sleep 45
until vm true 2>/dev/null; do sleep 15; done
play verify.yml | tee "$work/verify.log" | sed -n '/stdout_lines/,/]/p'
step passed
