# Plan

## 1. Prepare (agent, laptop)

- [x] Choose the image, inspect its first boot ([0001](decisions/0001-image.md))
- [x] Reconstruct what was done by hand ([old card](old-card.md))
- [x] Image script, guarded flash script, Ansible
- [x] Test on the r7 image in an arm64 VM (results in the log below; harness in `tests/vm/`)
- [x] First commit
- [x] ~~Re-run `tests/vm/` once as committed~~ skipped by the user's choice: the scratch harness passed and a run takes minutes

## 2. Reinstall (user, about an hour)

- [x] Copy old scans (`~/cubie-old-scans`), power off, label and keep the old card
- [x] [Install](install.md) steps 3 to 6
- [ ] Acceptance list (step 7), especially 6.40 on paper and a scan
- [x] AirSane on the board ([0009](decisions/0009-airsane.md)); the "before" measurement was skipped by the user's choice
- [ ] AirSane: the phantom ADF locks the scanner; report it to sane-backends ([0011](decisions/0011-no-adf-workaround.md))
- [x] Phone printing and scanning: Mopria works fine on the Pixel; the built-in Default Print Service is finicky
- [x] Confirm CPU idle on real hardware: `verify.yml` shows a cpuidle driver (`psci_idle`)

### Open issues (from 2026-11-23)

- **Scanner stuck in "SCANNING": cause found** (measured 20:25): a scan with the "Feeder"/"ADF"
  source, which `pixma` offers but the MF4320d doesn't have. `source=1`, `Error in response phase.
  cmd:de20`, `abort_session() failed EIO`; only a printer power cycle frees it. Documented, no
  patch ([0011](decisions/0011-no-adf-workaround.md)). Sleep is not a trigger (measured).
  Next: report upstream (draft: `docs/upstream-pixma-adf.md`, not committed), then turn off the
  debug logging: `sudo systemctl unset-environment SANE_DEBUG_PIXMA && sudo systemctl restart airsaned`.
- **Android print "printer isn't available"** (worked around: use Mopria) (Pixel 8, Android 17, Default Print Service): it finds
  the queue and its options, but greys out Print. CUPS logged `Unable to encrypt connection` at the
  same moment. After clearing the Default Print Service's storage it printed (20:11, `Print-Job`
  `successful-ok` in `access_log`), but only after reopening the print dialog: finicky. CUPS logged
  no errors for the failed attempts, so the cause is on the phone side (hypothesis: Android greys the
  printer out until its status check or mDNS answer arrives). Mopria (print and scan) works fine
  on the same phone (user, 2026-11-23): recommended on Android. Only if `error_log` shows TLS errors
  at a failure, consider not advertising IPPS.

## 3. Cooling (one change per measurement)

- [ ] Measure r7 with the cooling exactly as it is now (isolates the effect of software)
- [ ] Fix pad and mounting ([heat](heat.md)), measure
- [ ] If needed: fan, measure
- [ ] Only then look at the 60 °C trip and possibly latching governor
      ([heat](heat.md)). `step_wise` first, never `user_space`; critical trip stays at 110 °C

## 4. Later

- [ ] Monthly: `scripts/check-versions.sh` (scanservjs, AirSane, Canon driver: none of them come from APT)
- [ ] Canon 6.40-1.10 (2026-10-21) is newer than the pinned 6.40-1.05: decide after the paper test with 1.05
- [ ] One week stable, then decide whether board package updates are wanted ([0004](decisions/0004-board-packages.md))
- [ ] Smart plug, if printing is rare
- [ ] NixOS experiment in its own session ([0007](decisions/0007-nixos.md))
- [ ] Each kernel release: look for `sun60i-a733` in `arch/arm64/boot/dts/allwinner` and `drivers/clk/sunxi-ng`

## Log

| Date | Change |
|---|---|
| 2026-11-22 | Read-only survey, baseline, documentation. Nothing changed on the board |
| 2026-11-22 | Decided on a fresh r7 + Ansible. Prepared image and playbooks. Nothing changed on the board |
| 2026-11-22 | VM test, prepared r7 image, Debian arm64 kernel: first boot (SSH on, no `rock`); `site.yml` fresh `ok=42 changed=22`, again `changed=0`, `--check` `changed=0`; reboot; `verify.yml` no failed units. Ports 22, 631, 8080 only; no exim4, cron, cups-browsed, ipp-usb, scanbd, inetd. Queue shared, A4, driverless attributes incl. duplex. Canon 6.40 `rastertoufr2` turned the CUPS test page into 113 KB of UFR II data without errors. `update.yml`: holds restored, WiFi module present for 6.6.98-6. Fixed on the way: first-boot dpkg lock race, empty package lists, exim4 via recommends, slow `service_facts` |
| 2026-11-23 | Reinstall on a duplicate card (original kept): flash, first boot, two reboots, `site.yml` `ok=42 changed=22 failed=0`, `verify.yml`: `psci_idle`, no failed units after the next reboot (`lightdm`, `plymouth-quit` were first-boot leftovers). WiFi up, SSH over WiFi only, ports 22, 631, 8080. Printer not yet connected: acceptance (step 7) pending |
| 2026-11-23 | SSH keys from GitHub with `ssh-import-id-gh` instead of pinned files ([0008](decisions/0008-github-ssh-keys.md)). Applied: `authorized_keys` holds only the two tagged GitHub keys. User names moved to untracked `ansible/host_vars/cubie.yml`; MIT license |
| 2026-11-23 | AirSane role ([0009](decisions/0009-airsane.md)): VM, fresh image `site.yml` `failed=0`, `airsaned` active, web 200 from the host, build packages removed again; second run found `changed=1` (apt-mark), fixed, not re-run. `scripts/check-versions.sh`: Canon 6.40-1.10 is newer than the pinned 1.05. SSH keys: add only ([0010](decisions/0010-add-github-keys.md)), after the old removal locked the VM out. man-db trigger off. `tests/vm/`: qcow2 snapshots (`--from configured`), no `--check` pass, `build.sh` subshell fix. Nothing changed on the board |
| 2026-11-23 | Acceptance, part: test page and a 2-page duplex job printed (also after the printer's sleep: jobs wake it); laptop finds `_ipp._tcp`. `radxa` added to `adm` (logs without sudo). AirSane deployed (`site.yml` `ok=55 changed=19 failed=0`, no before-measurement): `_uscan._tcp` with platen and ADF, scans work, one unexplained stuck scan (open issues). AGENTS.md: only lasting changes need Ansible |
| 2026-11-23 | `site.yml --check --diff`: `ok=39 changed=0 failed=0 skipped=26`: the board matches Ansible (after `adm`, AirSane). Android: Mopria prints and scans fine |
