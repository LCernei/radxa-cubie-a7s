# arm64 VM test

Runs `ansible/` against the real prepared r7 image in QEMU (emulated, no KVM), before touching the
board. It boots the image's own root filesystem with Debian's generic arm64 kernel, because
Radxa's kernel has no virtual hardware drivers.

```sh
nix develop
tests/vm/build.sh     # images/vm/: disk from images/cubie-a7s-r7.img + Debian cloud kernel (~4 GB)
tests/vm/run.sh &     # boots; SSH on 127.0.0.1:2222 only
tests/vm/e2e.sh       # first boot -> site.yml twice -> --check -> reboot -> verify.yml (~60 min)
kill %1               # stop the VM
```

Logs land in `images/vm/`. Each `build.sh` starts from a pristine image.

Covers: first-boot edits, playbook on a fresh image, idempotency, drift check, reboot, services,
ports, the Canon filter (by hand: see the log in `docs/plan.md`).

Does not cover: Radxa's kernel, bootloader, WiFi, CPU idle, USB printer and scanner, temperatures.
The image's default `radxa` password is used; it's a throwaway VM.
