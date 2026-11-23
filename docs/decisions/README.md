# Decisions

One file per decision. Don't rewrite an accepted one: add a new file that supersedes it.

| # | Decision | Status |
|---|---|---|
| [0001](0001-image.md) | Reinstall on the spare card from Radxa `rsdk-r7` trixie cli | accepted 2026-11-22 |
| [0002](0002-ansible.md) | Every change to the fresh image lives in Ansible | accepted 2026-11-22 |
| [0003](0003-printing-driver.md) | Canon UFR II 6.40 on the server, driverless on clients | accepted 2026-11-22, paper test pending |
| [0004](0004-board-packages.md) | Hold kernel, bootloader and WiFi driver | accepted 2026-11-22 |
| [0005](0005-exposure.md) | Fewer users, ports and services | accepted 2026-11-22; key row superseded by 0008 |
| [0006](0006-cooling.md) | Fix the thermal contact first, then a slow quiet fan | proposed, needs hardware |
| [0007](0007-nixos.md) | NixOS later, on another card | deferred |
| [0008](0008-github-ssh-keys.md) | SSH keys from GitHub with `ssh-import-id-gh`, none in the repo | superseded by 0010 |
| [0009](0009-airsane.md) | AirSane (eSCL) on port 8090, built from a pinned source release | accepted 2026-11-23, deployed, flatbed scans work; ADF trap in 0011 |
| [0010](0010-add-github-keys.md) | Add the GitHub keys of the listed users, keep other keys | accepted 2026-11-23 |
| [0011](0011-no-adf-workaround.md) | Document the phantom ADF of the MF4320d, no patch; report it upstream | accepted 2026-11-23 |
