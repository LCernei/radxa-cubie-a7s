# Hardware

| | |
|---|---|
| Board | Radxa Cubie A7S v1.10, 50.8 x 50.8 mm, four M2.5 holes on a 43.8 mm square |
| SoC | Allwinner A733 (sun60iw2): 6x Cortex-A55 up to 1794 MHz, 2x Cortex-A76 up to 2002 MHz; bare die, on the underside |
| RAM | 4 GB LPDDR5 |
| Storage | microSD only (32 GB card); no eMMC fitted. Boot order: microSD, then eMMC |
| WiFi/BT | AIC8800D80 on USB, behind the onboard WCH hub (`1a86:8091`); vendor DKMS driver, no mainline driver |
| Ethernet | 1 GbE, `end0` |
| USB-A | 2.0: the printer, Canon i-SENSYS MF4320d (`04a9:26ee`, "MF4320-4350"): laser printer with duplex, flatbed scanner, **no ADF** |
| USB-C 1 | marked 5V, next to the colored header: power in (5 V, 3 A or more), no video |
| USB-C 2 | USB 3, DisplayPort Alt Mode: the USB-C to HDMI adapter |
| Fan header J7 | 0.8 mm pitch, 1 GND, 2 PWM (PJ27, kernel drives 40 kHz), 3 +5 V; no tachometer |
| 30-pin header | 2.54 mm. Pin 1 3.3 V; 2, 4 5 V; 6, 9 GND; 8 UART0 TX, 10 UART0 RX (115200 8N1, `ttyAS0`) |
| Buttons | USB BOOT: hold while powering on for FEL mode |
| Cooling now | no case, no fan, a loose salvaged heatsink on a blue pad. See [heat](heat.md) |

Sources: [Radxa hardware info](https://docs.radxa.com/en/cubie/a7s/hardware-use/hardware-info),
[schematic](https://dl.radxa.com/cubie/a7s/hw/radxa_cubie_a7s_schematic_v1.10.pdf),
[2D drawing](https://dl.radxa.com/cubie/a7s/hw/radxa_cubie_a7s_2d_dimensions_v1.10.pdf), and the old card's
device tree (fan PWM period).

Quirks seen so far:

- No USB serial adapter here, so no boot console: recovery is Ethernet, the HDMI console, or the card in a reader.
- `radxa-cubie-a7s.local` sometimes fails to resolve. WiFi power save is a possible cause (hypothesis).
- The scanner driver (`pixma`) wrongly lists an ADF for the MF4320d. Choosing it locks the scanner on
  "SCANNING" until the printer is power-cycled ([0011](decisions/0011-no-adf-workaround.md)).
- No power sensor on the board. A USB-C meter is the only way to measure draw.
