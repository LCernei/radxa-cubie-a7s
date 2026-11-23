# Install from scratch

Laptop commands run from the repository root. Allow about an hour.

## 1. Prepare (laptop)

```sh
nix develop                      # or `direnv allow` once
scripts/prepare-image.sh         # downloads, verifies, writes images/cubie-a7s-r7.img
```

## 2. Retire the old card

Copy any scans worth keeping, then power off and label the card. **Don't erase it.**

```sh
scp -r radxa@radxa-cubie-a7s.local:/var/lib/scanservjs/output ~/cubie-old-scans
ssh -t radxa@radxa-cubie-a7s.local sudo poweroff
```

## 3. Flash the new card (laptop)

```sh
lsblk -d -o NAME,SIZE,TRAN,RM,MODEL     # before and after inserting the card
sudo scripts/flash.sh /dev/sdX          # asks for confirmation, verifies by reading back
```

## 4. First boot

Connect Ethernet and power. Power goes into the USB-C port marked 5V, next to the colored pin
header. Use a 5 V / 3 A or better supply. The other USB-C is the one that can do HDMI.

Wait **5 minutes** without interrupting: the first boot creates the user, replaces SSH host keys
and grows the filesystem.

If `radxa-cubie-a7s.local` doesn't resolve, take the address from the router (Ethernet has a
different MAC and IP than WiFi), or connect HDMI and a keyboard and run `ip -br a`.
Use that address below, and add `-e ansible_host=<ip>` to the playbook commands.

```sh
ssh-keygen -R radxa-cubie-a7s.local     # new card, new host key
ssh-copy-id radxa@radxa-cubie-a7s.local # password: radxa
ssh radxa@radxa-cubie-a7s.local
```

On the board:

```sh
passwd                                  # immediately; the default is public
sudo reboot                             # then once more, to prove reboots work before changing anything
```

## 5. Configure (laptop)

Once per laptop: copy `ansible/host_vars/cubie.yml.example` to `cubie.yml` (not in git) and fill in the
timezone and the GitHub users whose keys may log in. One of them must have this laptop's key, or `site.yml` locks you out.

```sh
cd ansible
ansible-playbook site.yml               # asks for the sudo (radxa) password
ansible-playbook verify.yml
```

## 6. WiFi (board, over Ethernet)

```sh
sudo nmcli --ask device wifi connect "NETWORK NAME"
nmcli -g GENERAL.STATE device show wlan0
sudo reboot
```

Unplug Ethernet and check that SSH comes back over WiFi.

## 7. Accept

- [ ] Printer in the USB-A port, switched on; `ls /dev/usb/lp0` exists
- [ ] Print a test page: `lp -d radxa /usr/share/cups/data/testprint`
- [ ] Print from a laptop and a phone, try duplex
- [ ] Scan at <http://radxa-cubie-a7s.local:8080>
- [ ] Power off, power on, print and scan again
- [ ] `ansible-playbook site.yml --check --diff` reports `changed=0`
- [ ] After 30 minutes idle: `scripts/measure.sh > docs/measurements/<date>-r7.tsv`
- [ ] Add a line to the log in `docs/plan.md` and commit

## Rescue without serial

| Symptom | Do |
|---|---|
| No SSH | HDMI adapter (must support DP Alt Mode) in the non-5V USB-C, keyboard in USB-A, log in on the console |
| No network | Ethernet, then `nmcli device` on the console |
| No boot, no picture | Card into the laptop: check `/boot/extlinux/extlinux.conf` on partition 3 |
| Give up | Power off, insert the old card (then `ssh-keygen -R radxa-cubie-a7s.local` again) |

The HDMI console is not tested on r7.
