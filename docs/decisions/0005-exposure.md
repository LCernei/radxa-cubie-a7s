# 0005 Less exposure

| Old card | New card | To undo |
|---|---|---|
| SSH passwords and keys | keys only | `10-keys-only.conf` in the base role |
| keys imported with `ssh-import-id` | the same two keys, pinned in `ansible/files/`; any other key is removed | `base_ssh_keys` |
| `rock` sudo user | not created | |
| `cupsctl --remote-admin --remote-any` | shared to the local subnet, no remote admin | admin through `ssh -L 6310:localhost:631 radxa@radxa-cubie-a7s.local`, then <http://localhost:6310/admin> |
| scanbd + inetd on 6566 | not installed; it only had its stock configuration | add a role if scanner buttons or network SANE are wanted |
| cups-browsed, ipp-usb | blocked by an APT pin | remove the pin |
| all 14 OCR languages | eng, ron, rus | `scanning_ocr_languages` |

scanservjs still has no login. Acceptable on a trusted LAN only: never forward port 8080.
