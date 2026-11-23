# 0010 Add the GitHub keys, keep the others

Supersedes [0008](0008-github-ssh-keys.md).

**Decision:** the base role adds the public keys of `base_github_users` from
`https://github.com/<user>.keys` with `ansible.posix.authorized_key`. Keys already in
`authorized_keys` stay. Nothing is removed. `ssh-import-id` is no longer used.

**Why:** the user's choice, 2026-11-23. Removing every untagged key needed tagging, a regex and
extra tasks, and it had a lockout bug: `ssh-import-id` skips a key that is already authorized
without its tag, and the removal task then deleted it (found in `tests/vm/`, where `e2e.sh` adds the
laptop key first). Adding only is one task, and it reports `changed=0` when the keys are there.

**Consequences:**

- A key deleted on GitHub, or one added by hand, stays on the board. Remove it through Ansible
  (`ansible.posix.authorized_key` with `state: absent`) when needed.
- `site.yml` still needs the board to reach github.com. A failed download stops the play before
  passwords are switched off.
- The comment of a matching key is set to GitHub's (empty), once: on the board, the
  `# ssh-import-id gh:<user>` tags go away on the first run after this change. The keys stay.
- The play still refuses an empty `base_github_users`: password login is switched off, so a fresh
  image needs a listed key.
- `ssh-import-id` stays installed on the current card (removing a package from the list doesn't
  uninstall it). Harmless.
