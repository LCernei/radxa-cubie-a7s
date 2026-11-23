# 0012 No NixOS on this board for now

Supersedes [0007](0007-nixos.md).

**Decision:** drop the NixOS experiment from the plan. The board stays on Debian (r7) with Ansible
as its declarative recipe.

**Why:** the user's choice (2026-11-23). NixOS would need the out-of-tree vendor kernel, bootloader
and the `aic8800` WiFi driver (see [options](../options.md)). The server depends on WiFi, and there
is no serial adapter to debug a boot or WiFi failure. The chance of a working, maintainable result
is too low for the effort.

**Reconsider only if** mainline gains the A733 device tree, clock driver and a WiFi driver that
works without vendor code, or the server moves to a board with upstream support (option G in
[options](../options.md)). The Ansible roles remain the specification for NixOS modules then.
