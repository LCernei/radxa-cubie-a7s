# 0006 Thermal contact first, then airflow

Proposed. Details and wiring: [heat](../heat.md).

- The SoC is a small bare die, so a thick pad of unknown quality and a loose heatsink are
  probably a large part of the temperature problem (calculated, not measured).
- Replace the pad with paste or a thin pad as the geometry allows, and secure a small heatsink
  without tilting it.
- If still hot: 40 mm Noctua NF-A4x20 5V on header pins 4 and 6, always on.
- The 0.8 mm fan connector is not used: awkward plug, and the kernel drives it at 40 kHz,
  outside the usual 25 kHz for PC PWM fans.
- Thermal trips and governor stay stock until there is a measurement with fixed cooling.
