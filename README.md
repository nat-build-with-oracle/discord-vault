# discord-vault

An **isolated [`pass`](https://www.passwordstore.org/) store just for Discord bot tokens** — kept
completely separate from your main `~/.password-store`, with token handling designed so secrets
**never touch a script's memory, shell history, or logs**.

Three faces, one behaviour:
- **`just`** — ergonomic front, self-documenting (`just` lists every recipe)
- **`dvault.ts`** — the logic (Bun)
- **`dvault.sh`** — a no-Bun fallback (pure bash)

## Why

Discord bot tokens end up scattered — a plaintext `.env` per repo, no backup, no single place that
answers *"which bot, which token, is it backed up?"*. `pass` solves the encryption + git-history
part; this wraps it with two guarantees that matter for credentials:

1. **Isolation** — every command pins `PASSWORD_STORE_DIR` to `~/.discord-vault`, so it can *never*
   read or write your main `~/.password-store`.
2. **Secrets never enter the tool** — token-touching commands (`add`, `show`) run `pass` with
   inherited stdio, so the secret flows **terminal ⇄ pass directly**. It is never captured into a
   JS string or a shell variable (the trap with `` $`pass show` `` — captured stdout would put the
   token in process memory, one stray log line from a leak).

## Install

```bash
# Bun version (recommended) — the #!/usr/bin/env bun shebang runs it directly
curl -fsSL https://raw.githubusercontent.com/nat-build-with-oracle/discord-vault/main/dvault.ts \
  -o ~/.local/bin/dvault && chmod +x ~/.local/bin/dvault

# no-Bun fallback (pure bash)
curl -fsSL https://raw.githubusercontent.com/nat-build-with-oracle/discord-vault/main/dvault.sh \
  -o ~/.local/bin/dvault && chmod +x ~/.local/bin/dvault
```

Needs: `pass` + `gpg` (`brew install pass gnupg`). Bun version needs `bun`. `just` version needs `just`.

## Use

```bash
dvault init nat@mba.wg      # one-time: create the vault, encrypted to your gpg key
dvault add penny            # paste the token at the prompt (never echoed)
dvault ls                   # list token names (values stay hidden)
dvault show penny           # reveal ONE token, only when you need it
dvault check                # read-only status: where, who can decrypt, what's inside
dvault rm penny             # remove
```

Stored as `discord/<name>-oracle-token`. Every write auto-commits to the vault's local git history.

With `just` instead: `just init nat@mba.wg` · `just add penny` · `just` (menu).

## Override the location

```bash
DISCORD_VAULT=~/some-other-dir dvault check
```

## Design notes

- `pass init <gpg-id>` encrypts to a key whose **private half never leaves the machine** — decrypt
  is local. To share a vault across machines, add each machine's *public* key as a recipient; never
  copy a private key.
- Not a Discord app creator. Making the app + resetting the token is a manual step in the Discord
  Developer Portal — this only *stores* the token you already have.

## Part of a fleet

This is the vault/backing-store layer. In a larger setup it pairs with a channel installer
(wiring the bot into a repo) and a credential registry (fingerprints, duplicate-token detection) —
this tool stays deliberately small: **store the secret, and get out of its way.**

---
by nh-oracle (AI) — from Nat · Apache-2.0
