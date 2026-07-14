#!/usr/bin/env bun
// dvault — isolated Discord bot-token vault (Bun edition)
// ─────────────────────────────────────────────────────────────────────────────
//  use:  bun dvault.ts {check | init <gpg-id> | add <name> | ls | show <name> | rm <name>}
//  or via justfile:  just check | just add penny | just show penny
//
//  ⚠️ SECRET-SAFETY — the whole reason this isn't `$`pass show``:
//  Bun's `$` shell CAPTURES stdout into a JS string. For a credential tool that is
//  exactly wrong — the token would live in this process's memory and could leak into
//  a log line or an error stack. So every `pass` call runs via Bun.spawnSync with
//  stdio:"inherit": the secret flows terminal ⇄ pass DIRECTLY and never touches JS.
//  We use `$` only for non-secret formatting (reading the public .gpg-id file).
// ─────────────────────────────────────────────────────────────────────────────

import { existsSync, readFileSync } from "node:fs"; // sync reads → no top-level await; also makes this a module

const HOME = process.env.HOME!;
const VAULT = process.env.DISCORD_VAULT ?? `${HOME}/.discord-vault`;
// pin the store dir → this can NEVER touch ~/.password-store
const env = { ...process.env, PASSWORD_STORE_DIR: VAULT };

const tokenPath = (name: string) => `discord/${name}-oracle-token`;

// run `pass` with the terminal wired straight through — secrets never enter JS memory
const pass = (...args: string[]) =>
  Bun.spawnSync(["pass", ...args], { env, stdio: ["inherit", "inherit", "inherit"] }).exitCode ?? 1;

const need = (arg: string | undefined, usage: string): arg is string => {
  if (!arg) { console.log(usage); return false; }
  return true;
};

const [cmd = "check", arg, ...more] = process.argv.slice(2);

switch (cmd) {
  case "check": {
    console.log(`vault:     ${VAULT}`);
    const idPath = `${VAULT}/.gpg-id`;
    const recipient = existsSync(idPath)
      ? readFileSync(idPath, "utf8").trim()
      : "(not initialized — run: dvault init <gpg-id>)";
    console.log(`recipient: ${recipient}`);
    console.log("tokens:");
    pass("ls");
    break;
  }
  case "init":
    // multi-recipient (heimdall's ask): pass encrypts every secret to ALL ids given, so a
    // second machine can decrypt its copy WITHOUT any private key ever crossing machines —
    // e.g. `dvault init nat@mba.wg nh@oracle.local` after importing nh's PUBLIC key here.
    if (need(arg, "usage: dvault init <gpg-id> [gpg-id2 ...]   (e.g. nat@mba.wg nh@oracle.local)")) {
      pass("init", arg, ...more);
      pass("git", "init");
    }
    break;
  case "add": // paste the token at pass's own prompt — typed straight into pass, never echoed
    if (need(arg, "usage: dvault add <name>   (e.g. penny)")) pass("insert", "-e", tokenPath(arg));
    break;
  case "ls":
    pass("ls");
    break;
  case "show": // reveals ONE token to your terminal (not into JS)
    if (need(arg, "usage: dvault show <name>")) pass("show", tokenPath(arg));
    break;
  case "rm":
    if (need(arg, "usage: dvault rm <name>")) pass("rm", tokenPath(arg));
    break;
  default:
    console.log("dvault — isolated Discord token vault (Bun)");
    console.log("usage: dvault {check | init <gpg-id> [gpg-id2 ...] | add <name> | ls | show <name> | rm <name>}");
}
