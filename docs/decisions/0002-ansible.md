# 0002 Ansible is the record of changes

`ansible/site.yml` is the whole difference between the fresh image and the server.

- Why Ansible: agentless (SSH and the image's Python), idempotent, `--check --diff` shows drift,
  readable as documentation. A shell script has no drift check, a saved image doesn't say what
  changed, Nix system-manager on Debian adds a second package world for little gain.
- Tools come from the flake dev shell, pinned by `flake.lock`.
- Downloads are pinned by version and SHA-256. No `curl | sudo bash`.
- `etckeeper` on the board records edits to `/etc` made outside Ansible:
  `sudo etckeeper vcs log --stat`.
- Deliberately outside Ansible, because they are secrets: the `radxa` password and the WiFi key.
  Both are manual steps in `docs/install.md`.
- Limit: Ansible only sees what it manages. A package installed by hand is not reported, so
  don't install by hand.
