# Agent notes: Radxa print/scan server

Documentation and (later) configuration for one Radxa Cubie A7S that serves an old USB Canon
i-SENSYS MF4320d printer/scanner over WiFi.

Goals, in order: printing and scanning keep working; less heat and power; current software;
eventually declarative (NixOS) if the hardware support allows it.

## Read first

- `docs/plan.md`: what to do next, and what is done
- `docs/decisions/`: what was decided and why. Supersede with a new file, don't silently reverse
- `docs/install.md`: from blank card to working server
- `docs/hardware.md`: the board, ports, pins
- `docs/heat.md`: why it runs hot and how to cool it
- `docs/options.md`: OS choices, mainline and NixOS status
- `docs/old-card.md`: the hand-configured old card (history, rollback)
- `tests/vm/`: try `ansible/` changes in an arm64 VM before the board

## Access

`ssh radxa@radxa-cubie-a7s.local` (key login). mDNS occasionally fails to resolve: retry.

## Rules

- **Every change to the board goes through `ansible/`.** No hand edits or ad-hoc installs. The only
  exceptions are the two secrets in `docs/install.md` (password, WiFi key).
- Run `ansible-lint` in the dev shell (`nix develop`) after editing `ansible/`.
- The board is a live device. Read-only inspection is fine. Get the user's OK for each change
  (packages, services, sysfs writes, reboot).
- WiFi is the normal link and there is no serial adapter. Before anything that could break boot or
  WiFi, confirm there is an SD backup, and that Ethernet or the HDMI console is available.
- Kernel, bootloader and WiFi driver packages are held (decision 0004). Don't unhold casually.
- Before rebooting into a new kernel, `dkms status` must list `aic8800-usb` as installed for
  that kernel. Without it there is no WiFi.
- Never write a bootloader, partition table or `dd` to the running card. Experiments go on a
  spare SD card.
- Keep `clk_ignore_unused`. Don't set thermal zones to `user_space` (it removes throttling).
- Don't read or store WiFi keys, password hashes or other secrets here. Don't test passwords.
- Community ports and vendor blobs are untrusted: pin by hash and read before building or flashing.
- Change one thing at a time. Run `scripts/measure.sh` before and after, at similar room
  temperature, after at least 30 minutes of uptime.
- Label statements as measured, read from source, reported by others, or hypothesis.
- After a change: tick `docs/plan.md` and add a line to its log; a new decision gets a file in
  `docs/decisions/`; hardware facts go in `docs/hardware.md`.

## Done means

The acceptance list in `docs/install.md` (step 7) passes.
