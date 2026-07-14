#!/usr/bin/env bash
# dvault — manage Discord bot tokens in an isolated `pass` store (no `just` needed)
# ─────────────────────────────────────────────────────────────────────────────
#  install:  curl -fsSL <gist-raw-url> -o ~/.local/bin/dvault && chmod +x ~/.local/bin/dvault
#  use:      dvault check | init <gpg-id> | add <name> | ls | show <name> | rm <name>
#
#  SAFETY: pins PASSWORD_STORE_DIR so it NEVER touches ~/.password-store;
#          token values are piped/prompted, never echoed except explicit `show`.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
export PASSWORD_STORE_DIR="${DISCORD_VAULT:-$HOME/.discord-vault}"

cmd="${1:-check}"; shift || true
case "$cmd" in
  check)
    echo "vault:     $PASSWORD_STORE_DIR"
    if [ -f "$PASSWORD_STORE_DIR/.gpg-id" ]; then
      echo "recipient: $(cat "$PASSWORD_STORE_DIR/.gpg-id")"
    else
      echo "recipient: (not initialized — run: dvault init <gpg-id>)"
    fi
    echo "tokens:"; pass ls 2>/dev/null | tail -n +2 || echo "  (none yet)"
    ;;
  init)
    # multi-recipient: every id given can decrypt — backup copies without moving private keys
    [ -n "${1:-}" ] || { echo "usage: dvault init <gpg-id> [gpg-id2 ...]   (e.g. nat@mba.wg nh@oracle.local)"; exit 1; }
    pass init "$@"; pass git init
    echo "✓ vault ready at $PASSWORD_STORE_DIR (recipients: $*, local git history)"
    ;;
  add)
    [ -n "${1:-}" ] || { echo "usage: dvault add <name>   (e.g. penny)"; exit 1; }
    pass insert -e "discord/$1-oracle-token"
    echo "✓ discord/$1-oracle-token saved (auto-committed, never echoed)"
    ;;
  ls)   pass ls ;;
  show)
    [ -n "${1:-}" ] || { echo "usage: dvault show <name>"; exit 1; }
    pass show "discord/$1-oracle-token"
    ;;
  rm)
    [ -n "${1:-}" ] || { echo "usage: dvault rm <name>"; exit 1; }
    pass rm "discord/$1-oracle-token"
    ;;
  *)
    echo "dvault — isolated Discord token vault"
    echo "usage: dvault {check | init <gpg-id> | add <name> | ls | show <name> | rm <name>}"
    ;;
esac
