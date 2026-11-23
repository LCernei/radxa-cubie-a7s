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
- [x] Acceptance list (step 7), 2026-11-23: all items pass (flatbed only; scanner lock-up after printer power-on documented)
- [x] AirSane on the board ([0009](decisions/0009-airsane.md)); the "before" measurement was skipped by the user's choice
- [x] Scanner lock-ups reported upstream: comment on sane-backends #462 ([0011](decisions/0011-no-adf-workaround.md)); phantom-ADF issue drafted, not filed
- [x] Phone printing and scanning: Mopria works fine on the Pixel; the built-in Default Print Service is finicky
- [x] Confirm CPU idle on real hardware: `verify.yml` shows a cpuidle driver (`psci_idle`)

### Open issues (from 2026-11-23)

- **Scanner stuck in "SCANNING": cause found** (measured 20:25): a scan with the "Feeder"/"ADF"
  source, which `pixma` offers but the MF4320d doesn't have. `source=1`, `Error in response phase.
  cmd:de20`, `abort_session() failed EIO`; only a printer power cycle frees it. Documented, no
  patch ([0011](decisions/0011-no-adf-workaround.md)). Sleep is not a trigger (measured).
  Next: report upstream (draft: `docs/upstream-pixma-adf.md`, not committed), then turn off the
  debug logging: `sudo systemctl unset-environment SANE_DEBUG_PIXMA && sudo systemctl restart airsaned`.
- **First scan after power-on, once the printer has slept, times out** (measured, reproduced
  twice by the user, 21:04 and 21:16: power-cycle the printer, wait for sleep, scan; the carriage
  starts, then stops mid-pass when pixma gives up). The scanner doesn't answer the
  start command (`de20`) within pixma's fixed 8 s (`s->rec_tmo = 8` in `pixma_open()`, read from
  source): countdown to "1 sec", `Error in response phase. cmd:de20`, `abort_session() failed EIO`,
  and the scanner is locked until a power cycle. First scans before sleep just make it (about 7.7 s:
  19:48, 20:51, 20:57); later scans, also after sleep, answer at once. The ADF failure (20:25) is the
  same timeout on the same command. So the core bug: pixma can't recover after the start command
  times out. In normal use it bites once after each printer power-on (and power cycling is the only
  way out, so after a lock-up: power-cycle, then do a first scan before the printer sleeps). Upstream: the same timeout is known
  for the MF4150 ([#462](https://gitlab.com/sane-project/backends/-/issues/462), [#858](https://gitlab.com/sane-project/backends/-/issues/858); no active pixma maintainer);
  MF4320d data added as a comment on #462 (2026-11-23). The phantom-ADF issue is drafted in
  `docs/upstream-pixma-adf.md` (not filed). Possibly later: an MR for a longer start timeout (like !1036).
  Debug logging is on in `airsaned` and `scanservjs` (runtime only, gone after a board reboot).
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
| 2026-11-23 | Board power cycle (21:22): all services up, no failed units; `_ipp`/`_ipps` at once, `_uscan` a few minutes later; test page `radxa-5` printed, scanservjs flatbed scan fine. Printer lock-up after power-on + sleep reproduced twice (21:04, 21:16), recovery rule in `install.md`. Debug logging gone with the reboot. Idle measurement running: board flat, SoC up, **no heatsink**, 65 °C at 5 min uptime |
| 2026-11-23 | Idle measurement `measurements/2026-11-23-r7-bare.tsv` (board flat, SoC up, no heatsink, no pad, room temperature not recorded): little/big average 65.6/65.7 °C (max 66.8), skin 37.1 °C, busy 0.0 %; big cluster cap 416 to 2002 MHz (average 733). Baseline 2026-11-22 (old card, loose heatsink): 67.0/66.7 °C, big capped at 416 MHz throughout. Not comparable as a cooling test (different card, setup and unknown room temperature); both idle near the throttling range |
