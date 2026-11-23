# 0001 Reinstall from rsdk-r7, trixie cli, 512

The user wants a fresh, tracked install on the spare card.

| Candidate | Verdict |
|---|---|
| **r7** (2026-11-05, trixie) | **chosen**: release channels, CPU idle, correct sensor map, matching bootloader |
| t6 (2026-09-21) | older, test channels |
| t4 (the old card) | no CPU idle, swapped sensors, [reboot hangs](https://github.com/radxa-build/radxa-a733/issues/34) (fixed in t5) |
| r6 (Radxa's download page) | Debian 11, out of LTS since 2026-08-31 |
| KDE variants | a headless server doesn't need them |
| `4096` variant | for UFS; SD cards use `512` |
| DockSeed, NixOS | see 0007 |

CPU idle and the sensor map were checked inside the r7 image, not taken from the changelog.

`scripts/prepare-image.sh` makes two changes to the image's first-boot file (`/config/before.txt`):

- SSH is always enabled. Stock enables it only when no display is attached, which would lock us
  out when the HDMI adapter is plugged in, and there is no serial console.
- `rock`/`rock` with sudo is never created.

The old card stays untouched as the rollback.
