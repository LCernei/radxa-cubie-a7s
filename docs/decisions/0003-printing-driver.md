# 0003 Canon UFR II 6.40 on the server

**Stock CUPS can't drive this printer.** The MF4320d is USB-only and speaks Canon's proprietary
UFR II LT. Driverless (IPP Everywhere, AirPrint) needs a printer that speaks IPP itself, and no
open driver for this model was found.

Use Canon's 6.40-1.05 arm64 package:

- official, released October 2026, lists Debian 13.4 arm64 as tested
- contains `CNRCUPSMF4350ZK.ppd` ("Canon MF4320-4350"), the model the old queue used; default is A4
- installed from the `.deb` in Canon's archive, pinned by SHA-256, without the interactive `install.sh`
- same queue name and device URI as the setup that worked with 6.30

Computers and phones need no Canon driver. CUPS shares the queue as a driverless/AirPrint
printer and does the conversion on the board.

If a paper test fails with 6.40, go back to 6.30: set these in `ansible/group_vars/print_server.yml`

```yaml
printing_canon_version: "6.30-1.10"
printing_canon_url: https://gdlp01.c-wss.com/gds/8/0100007658/49/linux-UFRII-drv-v630-m17n-10.tar.gz
printing_canon_sha256: 793c580570555d0694732264815bb849cfb5770fa3168e83b944819738fdb022
```

and run `sudo apt remove cnrdrvcups-ufr2-uk` once first, as APT won't downgrade by itself.
