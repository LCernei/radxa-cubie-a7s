#!/usr/bin/env bash
# Boot the test VM. SSH, CUPS, scanservjs and AirSane are forwarded to 127.0.0.1 only.
set -euo pipefail
cd "$(dirname "$0")/../../images/vm"
exec qemu-system-aarch64 -M virt -cpu cortex-a76 -accel tcg,thread=multi -smp 6 -m 4096 \
  -kernel vmlinuz -initrd initrd -append "root=/dev/vda3 rw console=ttyAMA0" \
  -drive file=disk.qcow2,format=qcow2,if=none,id=d0 -device virtio-blk-pci,drive=d0 \
  -netdev user,id=n0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:26310-:631,hostfwd=tcp:127.0.0.1:28080-:8080,hostfwd=tcp:127.0.0.1:28090-:8090 \
  -device virtio-net-pci,netdev=n0 -display none -serial file:console.log -monitor none
