# 0007 NixOS later

Deferred. The board needs out-of-tree kernel, bootloader and WiFi (see [options](../options.md)),
and there is no serial console to debug a failed boot. Get a stable, recorded Debian first.

Reconsider when a 3.3 V USB serial adapter and a third card are available, or when mainline gains
the A733 device tree and clock driver. The Ansible roles will then be the specification for the
NixOS modules.
