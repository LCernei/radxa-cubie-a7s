# 0008 SSH keys from GitHub

Supersedes the key row of [0005](0005-exposure.md).

**Decision:** no public keys in the repository. The base role installs `ssh-import-id` and runs
`ssh-import-id-gh` for `base_github_users` (the two users of the old card), as was done by hand on the old
card. The names live in `ansible/host_vars/cubie.yml`, which is not in git (template: `cubie.yml.example`);
the play refuses to run with an empty list. Keys in `authorized_keys` without the tag `# ssh-import-id gh:<listed user>` are removed.

**Why:** the user's choice. Keys stay managed in one place (GitHub), and adding or removing a person is
one line in `group_vars`.

**Consequences:**

- Whoever controls one of these GitHub accounts can add a key that the next `site.yml` authorizes.
- `site.yml` needs the board to reach github.com. If the import fails, or a user has no keys, the play
  stops before any key is removed.
- A key deleted on GitHub stays on the board: `ssh-import-id` only adds. Remove the line by hand
  through Ansible, or remove and re-add the user.
- Checked 2026-11-23: the GitHub keys of both users are the keys that were pinned before, and
  the first user's key is the laptop's `~/.ssh/id_ed25519.pub`.
- `tests/vm/e2e.sh` bootstraps the VM with `$SSH_PUBKEY` (default `~/.ssh/id_ed25519.pub`), which must be
  one of the GitHub keys, or the VM locks the test out after `site.yml`.
