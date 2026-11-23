# Heat

Measured on the old card (2026-11-22) unless marked otherwise.

## Baseline (measured)

[Raw data](measurements/2026-11-22-baseline.tsv), 16 to 24 minutes after boot:

- CPU 0.0-0.3% busy, both clusters almost always capped at 416 MHz, the minimum
- SoC rose from 64 to 68.7 °C and levelled off around 68 °C; skin sensor about 37.6 °C
- Printer not connected, no display, no Ethernet link

So it is hot while doing nothing at the lowest clock. Lower frequency limits, a powersave
governor or removing idle daemons cannot help much. The heat is in idle and static power, and in cooling.

Power draw was not measured: the board exposes no usable sensor. A USB-C meter would show it.

## Software causes

### 1. CPU idle is compiled out (measured, read from source)

- Installed 6.6.98-3: `# CONFIG_CPU_IDLE is not set`, no cpuidle driver. Idle cores only do WFI
  and never power down, although the device tree describes core and cluster sleep states.
- Radxa enabled it on 2026-09-04. The r7 image's kernel (6.6.98-6) has `CONFIG_CPU_IDLE=y` and
  `CONFIG_ARM_PSCI_CPUIDLE=y` (read from the image).
- Not known yet: how many degrees it saves. `verify.yml` shows whether a cpuidle driver is active.

### 2. Cluster temperature sensors are swapped (read from both device trees)

In -3, `cpub_thermal_zone` (A76) reads sensor 0 and `cpul_thermal_zone` (A55) reads sensor 3.
In r7 (6.6.98-6) they are exchanged, so each zone throttled on the other cluster's temperature.

### 3. Throttling starts at 60 °C and may latch (measured, read from source)

- Both CPU zones use `power_allocator` with a single passive trip at 60 °C. Radxa staff said on
  [their forum](https://forum.radxa.com/t/extreme-throttling-introduced-on-a733/30688) that 60 °C
  matches their other products and is not a tuned value.
- In upstream 6.6.98 `gov_power_allocator.c`, a single passive trip means there is no switch-on
  temperature: the controller always runs and never resets its integral. With the default cutoff
  of 0 that integral only moves towards less power.
- This fits what was seen: the zone named cpub was capped at 416 MHz already at 57 °C, below the
  trip. That it is this mechanism is a hypothesis (the vendor source was not compared).
- The r7 device tree has the same trips, so the reinstall alone does not fix this.
- At 68 °C idle it costs speed (slow scan processing and print rendering). It does not cause the
  heat, and lifting it adds heat under load.
- Radxa's forum workaround, the `user_space` governor, removes throttling completely. Don't use it.

## Not worth changing

| Idea | Why not |
|---|---|
| Lower CPU max frequency | already at the minimum |
| NPU governor (`performance`, 1008 MHz) | the device is runtime-suspended |
| WiFi power save | already on |
| Remove `clk_ignore_unused` | Radxa added it as a fix; may hang boot |
| USB autosuspend for WiFi | small gain, risks the only link |
| Suspend | can't serve jobs while asleep; reported to reset the board on mainline |

## Cooling

Geometry from Radxa's drawing and photos (see [hardware](hardware.md)); die size estimated from a photo.

### What is under the heatsink

- Board 50.8 x 50.8 mm, four 2.7 mm holes (M2.5) on a 43.8 mm square
- The SoC is on the **underside**, opposite the Ethernet and USB connectors, next to the SD slot
- Package about 15 x 15 mm, with a **bare silicon die of about 6.5 x 8 mm** in the middle
- RAM, SD slot, camera connector and small components are close around it

So: lay the board with the SoC facing up (M2.5 standoffs, at least 20 mm, on the connector side
would clear the Ethernet jack), never SoC-down on a table.

### The pad probably costs a lot

Temperature drop = power x thickness / (conductivity x area), through a die of about 52 mm².
Calculated for 2 W:

| Between die and heatsink | Drop |
|---|---|
| 1.5 mm pad, really 1.5 W/mK (common for cheap blue pads) | ~38 °C |
| 1.0 mm pad, 1.5 W/mK | ~26 °C |
| 0.5 mm pad, really 6 W/mK | ~3 °C |
| paste, 0.05 mm, 4 W/mK | under 1 °C |

The SoC's real power is unknown and some heat leaves through the board, so read this as a
comparison, not a prediction. A loose heatsink is worse than any row here.

### Fixing the heatsink

Work powered off and unplugged.

1. Lift the heatsink. The die should have left a clear, even imprint in the pad.
2. With a straight edge, see whether the die is the highest point under the heatsink footprint.
   - Highest: paste (non-conductive) or a 0.5 mm pad.
   - Something is taller: use a heatsink no bigger than the package (14-15 mm square), or keep a
     pad just thick enough. Don't press harder to close a gap.
3. Cover the parts of the heatsink's underside that overhang components with Kapton tape.
   Sliding metal over a powered board can short it.
4. Secure it. **A zip tie is fine, with care:**
   - 2.5 mm ties fit the holes. Run one diagonally between the holes: the diagonal from the corner
     nearest the SoC passes about 2 mm from the die centre. A second one may only steady it.
   - Tighten by hand until it stops sliding, no more. Bare dies chip at edges and corners when
     a heatsink tilts, so keep it parallel (soft foam under overhanging sides helps).
   - The board must not bow. Keep ties off the SD slot, the button and the connectors.
   - A small light heatsink is safer here than a big PC one. Better still: M2.5 screws with
     springs and a crossbar.
   - Don't rely on thermal adhesive tape alone: the die is a tiny gluing area.
5. Measure after 30 minutes, at a noted room temperature.

### Fan

Try step 5 without a fan first. If it stays above about 60 °C idle, or you want margin:

**Noctua NF-A4x20 5V** (3-pin, not 12 V): 40 x 20 mm, at most 14.9 dB(A), about 0.1 A.
Effectively silent at a metre. A 5 V 40 mm fan from no-name brands is usually much louder.

| Fan wire (3-pin model) | 30-pin colored header |
|---|---|
| red, +5 V | pin 4 |
| black, GND | pin 6 |
| yellow, RPM | **not connected** (it must not touch 5 V) |

- Two male-to-female jumper wires, no cutting or soldering.
- Pins 2 and 4 are 5 V, pins 6 and 9 GND, **pin 1 is 3.3 V**. Find pin 1 on the silkscreen, don't
  count from a guessed end, and wire it with the power off.
- On the **PWM** (4-pin) model the colours differ: yellow is +5 V and green is RPM.
- Mount it with the bundled rubber pins or ties to the heatsink, blowing onto the fins, not
  touching the board.

The board's own fan connector (J7: 1 GND, 2 PWM, 3 +5 V) has a 0.8 mm pitch, so normal fan plugs
don't fit. See [decision 0006](decisions/0006-cooling.md).
