# 0004 Hold board packages

There are reports of A733 boards not booting after `apt upgrade`
([A7S, t3](https://github.com/radxa-build/radxa-a733/issues/24),
[A7Z](https://github.com/radxa-build/radxa-a733/issues/16)), and this setup has no serial console.
r7 already has the fixes that matter, so there is no urgent reason to move.

- Kernel, headers, U-Boot packages and the WiFi DKMS driver are held.
- Debian security updates install automatically.
- Everything else: `ansible-playbook update.yml`.
- Board packages: image the card, then `ansible-playbook update.yml -e update_board=true`.
  It checks that each installed kernel has the WiFi module and never reboots.
  Connect Ethernet and reboot twice (the reported failure appeared on the second reboot).

This trades "newest kernel" for "boots". Newest userspace is the NixOS experiment's job.
