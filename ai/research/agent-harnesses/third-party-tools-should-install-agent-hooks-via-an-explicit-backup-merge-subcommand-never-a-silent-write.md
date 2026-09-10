---
title: "A third-party tool should register agent hooks through an explicit backup-then-merge-by-key subcommand, never a silent write — and the hook itself can only detect and propose, because no hook can exit its TUI, switch its model, or inject input"
date: 2026-09-10
topic: agent-harnesses
tags: [hooks, claude-code, codex, config-ownership, tui, process-model, tmux, least-astonishment]
status: verified
sources: [cc-hooks-docs, codex-hooks-docs, codex-binary, precommit, husky, lefthook, fzf, rustup, nvm, starship, hookyard, ccusage, cc-issues, execve, setsid, tty-ioctl, tiocsti-kconfig, ubuntu-tiocsti, local-probe]
source_session: b9e12532-351b-43c0-a858-171dee902cb9
---

## CLAIMS

### What a hook cannot do

- No documented mechanism lets a Claude Code hook terminate its own session. `Stop` with `decision: "block"` prevents a turn from completing; it does not exit the program. Hook exit code 2 blocks the action on events that support blocking. No exit code or output field ends the session [cc-hooks-docs]
- No Claude Code hook output field sets model or effort. `PreModelSwitch` exists and can only *deny* a user-initiated switch; there is no field that triggers one [cc-hooks-docs]
- No Claude Code hook can invoke a slash command or queue input. `additionalContext` is prepended for the model to read, not executed [cc-hooks-docs]
- Codex's hook system is a near-port of Claude Code's, with 12 events (`PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`, `Stop`, `Interrupt`). The Codex binary's own JSON schema carries the comment "Claude requires `reason` when `decision` is `block`; we enforce that semantic rule during output parsing rather than in the JSON schema" [codex-binary]
- Codex hook inputs report `model` as a read-only field; no output schema exposes a settable `model` or `reasoning_effort`. Codex `Stop` + `decision: "block"` does the opposite of terminating — it creates a continuation prompt [codex-binary]
- A child process cannot replace its parent's process image. `execve` replaces only the caller: "This causes the program that is currently being run by the calling process to be replaced with a new program" [execve]
- Killing the TUI does not hand the terminal to the hook. On session-leader death the kernel sends `SIGHUP` to the foreground process group; the terminal reverts to whatever remains the session leader, usually the launching shell [tty-ioctl]
- `TIOCSTI` keystroke injection is gated by `CONFIG_LEGACY_TIOCSTI` (Linux 6.2+). Upstream default is `y`, but Ubuntu disabled it from 24.04 / kernel 6.8 and Arch since ~6.2.6, so an unprivileged process cannot rely on it [tiocsti-kconfig; ubuntu-tiocsti]

### What a hook can do

- A hook CAN spawn a detached process that replaces the TUI's tmux pane. Verified on an isolated `tmux -L` socket: a `setsid` child outlived its parent and ran `tmux respawn-pane -k`, taking the pane from `OLD-TUI-RUNNING` to `NEW-TUI-RUNNING`. The hook must detach and exit rather than wait, since it is a child of the process being killed [local-probe]
- This distinction is load-bearing: a hook cannot make its own parent become another program, but it can cause something outside the pane to do the replacement [local-probe; execve]

### Config ownership: observed practice

- Explicit-install-subcommand is the norm for hooks, not auto-install. `pre-commit install` is a separate required step, defaults to *migration mode* that preserves existing hooks ("if you have existing hooks `pre-commit install` will install in a migration mode which runs both your existing hooks and hooks for pre-commit"), requires `-f` to overwrite, and ships a paired `uninstall` that "will restore your hooks to the state prior to installation" [precommit]
- Husky REVERSED an auto-install design. v4 auto-installed via `postinstall`; v5+ dropped it because postinstall scripts "have very real consequences for your users" — hidden output made failures undebuggable and package-manager caching made it unreliable [husky]
- Lefthook auto-installs via `postinstall` but skips under `CI=true` and documents idempotency; pnpm blocks it by default pending explicit allowlisting [lefthook]
- Shell-rc practice is ask-or-document, not silent append. `rustup-init` prompts "Modify PATH variable? (Y/n)" and promises reversal [rustup]. fzf asks "Do you want to update your shell configuration files?" — added after users objected to silent edits [fzf]. starship, direnv and zoxide document a snippet and never edit [starship; direnv-zoxide]
- nvm is the outlier that auto-appends to `.bashrc`/`.zshrc`, and is also where breakage concentrates: wrong file targeted when the login shell differs, and init-order races [nvm]
- The nearest named principle is the Principle of Least Astonishment (Raymond, *The Art of Unix Programming*: "In interface design, always do the least surprising thing"). No canonical essay states "never modify user config without consent" in those words; the fzf thread is the closest first-person articulation [fzf]

### The specific file is already unsafe to write naively

- Claude Code's OWN tooling has open data-loss bugs on `settings.json`: a partial rewrite strips `statusLine`, `enabledPlugins` and `hooks` mid-session (#62486); a plugin contributing a `UserPromptSubmit` hook writes `null` over the user's entry for that key on every `/reload-plugins` (#53643); plugin-marketplace operations reverted the file to an older snapshot, losing custom permissions (#15339) [cc-issues]
- Codex's loader merges `~/.codex/hooks.json` with a repo-level file by a stable `statusMessage` key rather than array index — merge-by-identity, specifically to avoid blind overwrite [codex-hooks-docs]
- Codex has a SECOND conflict surface beyond `hooks.json`: `config.toml` holds `[hooks.state]` entries keyed `"<path>:<event>:<index>:<subindex>"` carrying a `trusted_hash` per hook. Writing `hooks.json` alone leaves Codex refusing the changed hook until its hash is re-trusted [local-probe; codex-binary]
- In the Claude Code hooks ecosystem, tools split between documented-snippet (ccusage ships a `statusLine` block to paste and never touches the file [ccusage]) and marketplace/plugin registration where the harness owns the merge. One installer, Hookyard, implements the middle pattern on this exact file: read the manifest, merge the hook block into the right event array, write a `.bak` snapshot beside the file, then write. Its stated practices are "add a dry-run mode... always create a backup before editing real settings, make install idempotent, make remove explicit" [hookyard]

## SOURCES

**cc-hooks-docs**
URL: https://code.claude.com/docs/en/hooks
Accessed: 2026-09-10
Quote: "Exit codes: 0 = Success (stdout parsed as JSON output if valid), 2 = Blocking error (blocks the action on events that support it), Other = Non-blocking error (action proceeds)."

**codex-hooks-docs**
URL: https://developers.openai.com/codex/config-advanced
Accessed: 2026-09-10
Quote: Manual setup is "open `~/.codex/config.toml`, create the file if it doesn't exist, append the `[hooks]` configuration, save... and start a new Codex session."

**codex-binary**
URL: local — @openai/codex 0.153.4 vendored binary, `strings` + extracted JSON schemas
Accessed: 2026-09-10
Quote: "Claude requires `reason` when `decision` is `block`; we enforce that semantic rule during output parsing rather than in the JSON schema" — a comment inside Codex's own hook schema.

**precommit**
URL: https://pre-commit.com/
Accessed: 2026-09-10
Quote: "Every time you clone a project using pre-commit running `pre-commit install` should always be the first thing you do."

**husky**
URL: https://blog.typicode.com/posts/husky-git-hooks-autoinstall/
Accessed: 2026-09-10
Quote: postinstall scripts "have very real consequences for your users".

**lefthook**
URL: https://lefthook.dev/installation/node/
Accessed: 2026-09-10

**fzf**
URL: https://github.com/junegunn/fzf/issues/392
Accessed: 2026-09-10
Quote: issue titled "Asking first: auto appending to `.bashrc`" — the installer now gates the edit behind "Do you want to update your shell configuration files?"

**rustup**
URL: https://github.com/rust-lang/rustup/issues/2106
Accessed: 2026-09-10
Quote: "Modify PATH variable? (Y/n)"

**nvm**
URL: https://github.com/nvm-sh/nvm/issues/1879
Accessed: 2026-09-10

**starship**
URL: https://starship.rs/
Accessed: 2026-09-10

**direnv-zoxide**
URL: https://direnv.net/ and https://zoxide.org/blog/zoxide-init-guide/
Accessed: 2026-09-10

**hookyard**
URL: https://www.developersdigest.tech/blog/claude-code-hooks-with-hookyard
Accessed: 2026-09-10
Quote: "add a dry-run mode... always create a backup before editing real settings, make install idempotent, make remove explicit."

**ccusage**
URL: https://github.com/ryoppippi/ccusage
Accessed: 2026-09-10

**cc-issues**
URL: https://github.com/anthropics/claude-code/issues/62486, /53643, /15339, /11392, /13281
Accessed: 2026-09-10
Quote: #62486 — "settings.json partial rewrite strips statusLine, enabledPlugins, hooks mid-session".

**execve**
URL: execve(2) man page
Accessed: 2026-09-10
Quote: "This causes the program that is currently being run by the calling process to be replaced with a new program... There is no return from a successful execve()."

**setsid**
URL: setsid(2) man page
Accessed: 2026-09-10

**tty-ioctl**
URL: tty_ioctl(4) and credentials(7) man pages
Accessed: 2026-09-10
Quote: TIOCSCTTY — "The calling process must be a session leader and not have a controlling terminal already... unless the caller has CAP_SYS_ADMIN, in which case the terminal is stolen."

**tiocsti-kconfig**
URL: https://github.com/torvalds/linux/blob/master/drivers/tty/Kconfig
Accessed: 2026-09-10

**ubuntu-tiocsti**
URL: https://bugs.launchpad.net/bugs/2046192
Accessed: 2026-09-10

**local-probe**
URL: local — isolated `tmux -L` socket probe and `~/.claude`/`~/.codex` read-only audit
Accessed: 2026-09-10
Quote: A `setsid` child survived its parent and ran `respawn-pane -k`; the pane went from `OLD-TUI-RUNNING` to `NEW-TUI-RUNNING`.

## SYNTHESIS

The useful split is between *registration* and *action*, and they have opposite answers.

Registration touches a file you do not own, so the question is consent and safety. The observed convention is neither of the two options that first come to mind. Silent auto-write is what almost nobody does for user-global config, and the one tool that does it — nvm — is also where the "edited the wrong file" and "broke on restart" reports cluster. But a bare README snippet is not the strong option either once an installer exists, because it hands every merge hazard to the user by hand for a feature whose whole point was automation. What real projects converge on is an explicit subcommand: `pre-commit install`, with migration mode preserving what is already there, `-f` required to overwrite, and a paired `uninstall`. Husky's reversal is the sharpest data point, because a maintainer with a working auto-installer removed it and explained why.

The hazard is not hypothetical for this particular file. Claude Code's own plugin system has three open issues where a partial read-modify-write of `settings.json` dropped fields it did not author. A third-party tool doing the same thing is walking into a failure mode the host has not solved for itself. That argues for the most conservative version of the installer pattern — back up beside the file, merge into the event array by a stable key, be idempotent, ship an explicit remove — which is exactly what the one tool operating on this file (Hookyard) already does. Codex's loader independently arrives at merge-by-identity rather than by array index, which is the same insight from the host side.

Action is a different question, and here the constraint is not etiquette but the process model. A hook cannot exit its own TUI, cannot change its model or effort, and cannot inject input; every one of those was checked against documentation and, for Codex, against the binary's own schemas. A child cannot replace its parent's image, and killing the parent returns the terminal to the shell rather than to the child. So the tempting design — a hook that notices a wall and relaunches in place — is not available as stated. What *is* available, and was verified rather than assumed, is a hook that spawns a detached process which replaces the pane from outside. That works, and it means the capability question is settled in favour of "yes, with tmux."

Which leaves the design question the capability answer does not settle: whether it *should* act. For an agent orchestrator the answer is no, and for a reason stronger than taste. Switching a worker to another account or provider changes which subscription gets consumed, and doing that on the tool's own initiative is a silent decision with a cost the operator never approved. The better shape is the same separation that registration already implies: the hook detects and prints the exact command, and a human or an explicit verb runs it. Detection is cheap and reversible; action is neither.
