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
- [x] Confirm CPU idle on real hardware: `verify.yml` shows a cpuidle driver (`psci_idle`)

## 3. Cooling (one change per measurement)

- [ ] Measure r7 with the cooling exactly as it is now (isolates the effect of software)
- [ ] Fix pad and mounting ([heat](heat.md)), measure
- [ ] If needed: fan, measure
- [ ] Only then look at the 60 °C trip and possibly latching governor
      ([heat](heat.md)). `step_wise` first, never `user_space`; critical trip stays at 110 °C

## 4. Later

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
