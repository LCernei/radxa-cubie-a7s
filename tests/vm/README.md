# arm64 VM test

Runs `ansible/` against the real prepared r7 image in QEMU (emulated, no KVM), before touching the
board. It boots the image's own root filesystem with Debian's generic arm64 kernel, because
Radxa's kernel has no virtual hardware drivers.

```sh
nix develop
tests/vm/build.sh                    # images/vm/disk.qcow2 from images/cubie-a7s-r7.img + Debian cloud kernel
tests/vm/e2e.sh                      # full: first boot -> site.yml twice -> reboot -> verify.yml (~60 min)
tests/vm/e2e.sh --from configured    # after a role change: from the last good full run (~15 min)
tests/vm/e2e.sh --from firstboot     # everything except the first boot (~50 min)
tests/vm/run.sh                      # just boot it to look around (Ctrl-C stops QEMU)
```

`e2e.sh` starts and stops the VM. A full run saves two qcow2 snapshots in the disk: `firstboot`
(after the image's first boot, laptop key added) and `configured` (after a passing run).
`--from configured` keeps that snapshot, so it doesn't drift with experiments, but it also doesn't
show what a fresh image does: run a full one (or `--from firstboot`) before changing the board.
List snapshots with `qemu-img snapshot -l images/vm/disk.qcow2`.

Ports on 127.0.0.1: SSH 2222, CUPS 26310, scanservjs 28080, AirSane 28090.

Logs land in `images/vm/`. Each `build.sh` starts from a pristine image and drops the snapshots.

Covers: first-boot edits, playbook on a fresh image, idempotency (second run `changed=0`), reboot, services,
ports, the Canon filter (by hand: see the log in `docs/plan.md`).

Does not cover: Radxa's kernel, bootloader, WiFi, CPU idle, USB printer and scanner, temperatures.
The image's default `radxa` password is used; it's a throwaway VM.
