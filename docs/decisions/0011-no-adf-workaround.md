# 0011 Document the phantom ADF, don't patch around it

Adds to [0009](0009-airsane.md).

**Problem (measured, 2026-11-23):** the MF4320d is flatbed only, but `pixma` (sane-backends
1.3.1, Debian 13) lists it with an ADF (`PIXMA_CAP_ADF` in `backend/pixma/pixma_imageclass.c`,
read from source). AirSane announces `is=platen,adf` and offers "Feeder"; scanservjs offers "ADF".
A scan with that source fails, `pixma` can't end the session (`Error in response phase. cmd:de20`,
then `abort_session() failed EIO`), and the printer display stays on "SCANNING". Restarting
`airsaned` doesn't help; only a power cycle of the printer does. AirSane reports the job `Aborted`,
`ResourcesAreNotReady`, and the client receives an empty, broken PDF.

**Decision:** no patch to AirSane, scanservjs or sane-backends. Document it, choose "Flatbed", and
report it upstream to sane-backends.

**Why:** the user's choice. Neither AirSane (`options.conf` options are applied before the client's
source, which wins) nor `pixma.conf` can hide a source, so a fix means carrying our own patch
through every update. The cause is in `pixma`, which is the right place to fix it.

**Consequences:**

- Anyone who picks "Feeder" or "ADF" locks the scanner until the printer is switched off and on.
  Clients that don't choose get the flatbed (AirSane's default).
- Upstream can't just drop the flag: the MF4320d, MF4330d and MF4350d share the USB ID
  `04a9:26ee`, and the last two have an ADF (`doc/descriptions/pixma.desc`, read from source). The
  fix needs ADF detection at run time, or a clean recovery when the ADF command fails.
- Revisit if upstream fixes it, or if the trap bites often enough to justify a patch.
