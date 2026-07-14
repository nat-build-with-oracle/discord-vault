# discord-vault — a `pass` store JUST for Discord bot tokens, isolated from ~/.password-store
# ─────────────────────────────────────────────────────────────────────────────
#  the LOGIC lives in dvault.ts (Bun); this justfile is the ergonomic front + self-docs.
#  run:   just <recipe>              (needs: brew install just  +  bun)
#  list:  just                       (shows every recipe from its comment)
#
#  SAFETY (baked into dvault.ts, not by discipline):
#   • PASSWORD_STORE_DIR is pinned → can NEVER touch ~/.password-store
#   • token-touching commands run `pass` with inherited stdio → the secret flows
#     terminal ⇄ pass directly and NEVER through the Bun process's memory
# ─────────────────────────────────────────────────────────────────────────────

# locate dvault.ts next to this justfile, wherever it's run from
dvault := "bun " + justfile_directory() / "dvault.ts"

# default: list recipes
_default:
    @just --list --justfile {{justfile()}}

# read-only status — where the vault is, who can decrypt it, token names
check:
    @{{dvault}} check

# ONE-TIME: create the isolated vault. recipients = gpg keys that can decrypt
# (one or more — e.g. `just init nat@mba.wg nh@oracle.local` for a backup copy)
init +recipients:
    @{{dvault}} init {{recipients}}

# add / update a token — paste it at the prompt (never appears in shell history)
add name:
    @{{dvault}} add {{name}}

# list token names (values stay hidden)
ls:
    @{{dvault}} ls

# reveal ONE token — only when you truly need the value
show name:
    @{{dvault}} show {{name}}

# remove a token
rm name:
    @{{dvault}} rm {{name}}
