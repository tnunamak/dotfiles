# beellama MTP work — archived 2026-09-11

16 commits of Tim's own work on a llama.cpp fork, preserved as patches because
they existed **only on local disk**.

## Why archived

`~/applications/beellama` is a fork of `Anbeeld/beellama.cpp` — a repo Tim does
not own and cannot push to. The 16 commits below were never on any remote, so
deleting that 3.9 GB checkout would have destroyed them permanently.

## It is not in use

Verified 2026-09-11:

- **No beellama process runs.** The live `llama-server` binaries are
  `llamacpp-official-505b1ed1-fa-all-quants-rpath` (the `ai.vivid.fish` gateway
  backend on :5051) and `llama-turboquant` (embeddings).
- **`~/.local/bin/llama-bee-start` prefers the official build** and only falls
  back to `beellama/build/bin/llama-server` if the official one is absent. It is
  not absent. So the service named `llama-bee` has been serving official
  llama.cpp, which is why nothing broke while the fork went 1692 commits stale.
- Built binary dates from **Jul 14**; last local commit **Jul 15** — two months
  untouched.

## Why the fork cannot be caught up

A dedicated merge attempt (sonnet/high) got through most of the 8 conflicted
files and then stopped, correctly, at two walls:

1. **Upstream deleted DDTree.** Tree-based speculation is a named feature of this
   fork — 9 references in its `server-context.cpp`, **zero upstream**. Merging
   would silently delete a working feature.
2. **Upstream rewrote the drafting loop.** `update_slots()` now uses one unified
   path for all speculative types, eliminating the fork's two-phase
   `mtp_drafting`/`mtp_batching` split — which is exactly what three of the MTP
   replay commits (`3a7eb4b2a`, `a0e6fc7ae`, `f4e14ddbe`) were purpose-built
   against.

Also found: the fork's DFlash ring-state save/restore (~150 lines) depends on
fields upstream no longer has. That code was authored by **Anbeeld (upstream)**,
not Tim — verified via `git log -S ring_state_size` — and upstream has since
replaced the whole ring-buffer design with `batch_inject`.

Grafting the loop-guard replay onto upstream's new loop while preserving DDTree
is a redesign needing live GPU testing, not a merge. Its judgment, which is the
right one: a textual resolution that compiles is achievable but not verifiable
without the exact MTP checkpoint-rollback scenario the design doc describes, and
a merge that looks done with an unverified core is worse than no merge.

## What is here

- `patches/` — all 16 commits via `git format-patch`, applicable with `git am`
- `mtp-loop-guard-force-close-fix-2026-07-13.md` — the design doc explaining the
  loop-guard intent

## The work itself

MTP loop-guarding, prompt-checkpoint retention, and speculative decoding:
checkpoint eviction policy (min-step aware, never evicting the current task),
loop-guard preservation through MTP rollback, replay hidden-state retention, and
stopping visible loops after a forced reasoning close. Note `dd93447ef` reverts
`f6040736c` — queued-cancellation servicing between decode batches was
deliberately backed out; do not resurrect it without reading both.

## Now on Forgejo — full history, not just patches

Pushed 2026-09-11 to **https://git.vivid.fish/tnunamak/beellama.cpp** (private).
Verified: Forgejo's `main` == local HEAD `d5b04438c`, with all 16 commits and
their full history reachable. The `patches/` directory here is now a redundant
second copy, kept because it costs 216 KB and survives independently of the
Forgejo instance.

Setup notes, since no repo on this machine used Forgejo before: `tnunamak` had
**zero SSH keys registered**, which is why `git@git.vivid.fish` returned
permission-denied. A key was added via the API, but SSH still failed, so the
push went over HTTPS with a temporary admin-generated token
(`peregrine-setup-0911`, scopes `write:user,write:repository`). That token has
been **revoked** and the remote URL rewritten without it. To push again, either
fix SSH (the registered key exists but the container's SSH path does not accept
it — likely a passthrough/port issue worth a look) or mint a fresh token.

Generating a token requires running as the git user:
`docker exec -u git forgejo forgejo admin user generate-access-token ...` —
as root it refuses with "Forgejo is not supposed to be run as root".

## Disposal

The checkout at `~/applications/beellama` is 3.9 GB and safe to delete now that
the history is on Forgejo. Nothing depends on it — `llama-bee` serves the
official build.
