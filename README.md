# Radxa Cubie A7S print/scan server

A Radxa Cubie A7S (Allwinner A733) that puts a USB Canon i-SENSYS MF4320d on the network over WiFi.
Everything changed from the stock image is in `ansible/`.

| | |
|---|---|
| SSH | `ssh radxa@radxa-cubie-a7s.local` |
| Printing (CUPS) | <http://radxa-cubie-a7s.local:631>, queue `radxa` |
| Scanning (scanservjs) | <http://radxa-cubie-a7s.local:8080> |
| Target OS | Radxa Debian 13 `rsdk-r7` cli + `ansible/site.yml` |
| Old card | `rsdk-t4`, configured by hand, kept as rollback |

## Everyday

```sh
nix develop && cd ansible
ansible-playbook site.yml --check --diff   # what drifted?
ansible-playbook site.yml                  # apply
ansible-playbook verify.yml                # health
ansible-playbook update.yml                # updates, not kernel or bootloader
```

## Documentation

- [Install from scratch](docs/install.md)
- [Decisions](docs/decisions/README.md)
- [Plan and log](docs/plan.md)
- [Hardware](docs/hardware.md), [heat and cooling](docs/heat.md)
- [Options: OS, mainline, NixOS](docs/options.md)
- [The old card](docs/old-card.md)
- [VM test](tests/vm/README.md)

## License

[MIT](LICENSE)
