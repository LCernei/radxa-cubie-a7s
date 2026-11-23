# Options

Researched 2026-11-22; upstream moves fast, so recheck before acting. "Reported" means a project's own claim, not tested here.

## Does Linux 7.3 support this board?

No, not by itself. Checked in torvalds/linux:

| Piece | First release containing it |
|---|---|
| PCK600 power domains | 7.2 or earlier |
| RTC clock driver, MMC binding | 7.3 |
| Pin controller, DMA controller | 7.4-rc |
| A733 device tree, main clock controller (CCU) | not in master |
| USB AIC8800 WiFi driver | not upstream at all |

A stock nixpkgs kernel (7.3.5 today) will not boot this board.

## Existing work

| Project | What it is | Fit for this board |
|---|---|---|
| [ritiek/nixos-cubie-a7s](https://github.com/ritiek/nixos-cubie-a7s) | NixOS 26.05, vendor 6.6.98; WiFi reported working | Best NixOS reference. Its kernel config fragments set neither CPU idle nor USB printer, it disables USB autosuspend and PCIe ASPM, uses January boot blobs, defaults to `root`/`nixos`, and has no license |
| [f-pd/nixos-a733](https://github.com/f-pd/nixos-a733) | NixOS framework, vendor kernel, CI, binary cache | Targets Orange Pi Zero 3W; mainline variant is empty so far |
| [DockSeed/a7s-linux-lts](https://github.com/DockSeed/a7s-linux-lts) | 6.18.64 + patches, release 2026-11-21 | CPU idle, USB printer module and WiFi driver included |
| [DockSeed/a7s-linux-mainline](https://github.com/DockSeed/a7s-linux-mainline) | 7.3 + patches, release 7.3.4-R1 | CPU idle, cpufreq, thermal, USB reported working. No WiFi included; Radxa's driver gained a 7.3 build fix |
| [DockSeed/a733-bootchain](https://github.com/DockSeed/a733-bootchain) | U-Boot + TF-A from source, vendor DRAM blob | Tested on 6 and 8 GB boards only; **this one has 4 GB**. Arms a watchdog that resets other kernels after about 16 s |
| [DockSeed/a7s-build](https://github.com/DockSeed/a7s-build) | Debian image recipe using the LTS kernel and that boot chain | Cheapest way to test that stack before porting it |

The DockSeed projects are weeks old, have one maintainer, are written largely by AI agents
(stated in their READMEs) and have no kernel developer review.

Armbian's `main` has a board file for the A7Z, none for the A7S.

## Choices

| | Option | Heat | Freshness | Effort | Risk |
|---|---|---|---|---|---|
| A | Update Radxa Debian, then tune | CPU idle, fixed sensor map | stable userspace, vendor 6.6 | about 1 hour | low |
| B | A + Nix package manager or containers for scanservjs | as A | fresh apps | few hours | low |
| C | Debian with DockSeed 6.18 | unknown, measure | fresh LTS kernel | half a day | medium |
| D | NixOS unstable + vendor kernel | about as A | fresh userspace, 6.6 kernel | weekend | medium |
| E | NixOS unstable + patched 6.18 or 7.3 | unknown, measure | newest | several weekends, then upkeep | high |
| F | Switch it off when unused (smart plug) | best | any | minutes | low; boot delay before printing |
| G | Board with upstream support, or an old thin client | depends | stock NixOS | money | low |

## Outcome

Option A was chosen as a fresh, tracked install ([decisions](decisions/README.md)); NixOS is
dropped for this board ([0012](decisions/0012-no-nixos.md)). The table above and the notes below are the input for
revisiting that. Path then: boot a DockSeed Debian image on a spare card first (does that stack
work with 4 GB, WiFi and USB?), E on 6.18 if it does, D if not.

## Taking the parts from the Debian image for NixOS

This is workable. It is option D.

| Part | Source | NixOS work |
|---|---|---|
| boot0, U-Boot | bytes from the r7 image or `u-boot-radxa-a733` | write at raw offsets in the SD image |
| Kernel, DTB, modules | `linux-image-6.6.98-7-aw2511` deb, or source for control over config | wrap as a kernel package; check NixOS's required config and initrd modules |
| WiFi driver | `radxa-pkg/aic8800` | out-of-tree module against that kernel |
| WiFi firmware | `aic8800-firmware` deb | `hardware.firmware` |
| Boot menu | none | `boot.loader.generic-extlinux-compatible` |
| Printer driver | nixpkgs `canon-cups-ufr2` 6.20, unfree | evaluates for aarch64; override to 6.40 to match decision 0003 |
| Scanner | nixpkgs SANE 1.4.0, `services.scanservjs` 3.3.0 | standard modules |

GPU, NPU, video, display and audio are not needed and can be left out.

Building: the laptop has no aarch64 binfmt. Either add
`boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` in `~/nixos` (slow for kernels), cross-compile
the kernel, or use an ARM CI runner. Compiling on a board with heat problems is a poor fit.
