# 0009 AirSane for eSCL scanning, built from source on the board

Adds a port to [0005](0005-exposure.md): 8090/tcp, AirSane.

**Decision:** serve the USB scanner as an eSCL (AirScan) scanner with AirSane 0.4.16, next to
scanservjs. The role `ansible/roles/airsane` downloads the tagged source archive pinned by SHA-256,
builds it on the board with `cmake`, installs `/usr/local/bin/airsaned`, and runs it from its own
systemd unit as `saned`. Clients (iOS/macOS Image Capture, Windows 10/11, Android Mopria,
`sane-airscan` on Linux) find the scanner over mDNS without drivers.

**Why:** the user wants eSCL. Debian 13 has no AirSane package (checked on the board:
`apt-cache policy airsane` is empty) and upstream publishes source only (no binaries, no
packaging). Building on the board is the smallest thing that stays in Ansible. A `.deb` built on the
laptop would keep compilers off the board, but needs our own packaging and arm64 emulation on the
laptop, for one small C++ daemon.

**How:**

- Only build packages that are missing are installed, and they are removed again (with
  autoremove) after the build. `gcc` and `make` stay because `dkms` needs them. The runtime
  libraries are marked manual first so autoremove keeps them. Build with `-j2` to limit heat.
- Not `make install`: it overwrites `/etc/default/airsane` and installs upstream's unit. Our unit has
  the options inline and some systemd hardening.
- The installed version is recorded in `/usr/local/share/airsane/version` (the binary built from a
  tarball doesn't know its version). Changing `airsane_version` rebuilds.
- Options: `--local-scanners-only`, no reset button, version not disclosed, web interface on
  (preview scans in a browser at port 8090).
- `/etc/airsane/access.conf`: `allow local on *`, the subnets of the board's interfaces. Anything else
  is denied.

**Consequences:**

- One more port without login on the LAN, like scanservjs on 8080. Never forward it.
- scanservjs and AirSane share one USB scanner. Hypothesis: two scans at the same moment fail with
  "device busy"; one at a time is fine. To be checked with the scanner.
- Measured: the MF4320d goes through the `pixma` backend (0.28.6, "generation 1" imageCLASS). It
  announces `is=platen,adf`, but the MF4320d is flatbed only (the ADF starts with the MF4330d), so
  clients offer an ADF source that cannot work, and choosing it locks the scanner until a power
  cycle (see [0011](0011-no-adf-workaround.md)).
- Updates are manual: `scripts/check-versions.sh` reports new releases; then set the version and
  hash, read the source diff, run `tests/vm/`, then `site.yml`.

**To undo:** remove `airsane` from `site.yml`, then `systemctl disable --now airsaned`, and delete
`/usr/local/bin/airsaned`, `/usr/local/share/airsane`, `/etc/airsane` and the unit, through Ansible.
