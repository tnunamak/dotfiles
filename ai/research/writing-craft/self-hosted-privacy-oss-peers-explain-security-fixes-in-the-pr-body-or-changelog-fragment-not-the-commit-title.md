---
title: "Self-hosted privacy-OSS peers (Synapse, Vaultwarden, Nextcloud) put the plain-language 'why this matters' explanation of a security/privacy fix in the PR body, GHSA advisory, or a dedicated changelog fragment — not in the commit title, and often not in the commit message body either"
date: 2026-08-14
topic: writing-craft
tags: [commit-messages, security-fixes, changelogs, oss-conventions, self-hosted, privacy, PR-descriptions]
status: draft
sources: [synapse-ghsa-hgcg, synapse-ghsa-cjh7, synapse-contributing-changelog, synapse-changelog-fragment-20090, nextcloud-pr-60884, nextcloud-contributing-conventional-commits, vaultwarden-pr-7061, vaultwarden-pr-7558-bad, standardnotes-pr-3029-bad]
source_session: unknown
---

## CLAIMS

- Synapse's own commit titles for shipped security fixes are terse ("Anchor the ends of our path patterns to prevent path traversal vulnerabilities", "Prevent theft of room aliases via remote join to room with illegitimate predecessor") and the commit bodies contain only `Fixes:` links to an internal GHSA advisory and internal issue tracker — no inline plain-language explanation of impact or exploitation. [synapse-ghsa-hgcg] [synapse-ghsa-cjh7]
- The actual outside-reader-legible explanation for those two Synapse fixes lives in the public GitHub Security Advisory (GHSA), not the commit: GHSA-hgcg-p9gx-fq5f states the impact in one paragraph ("When Synapse is protected by a reverse proxy... this can lead to a bypass of reverse proxy rules, allowing unintended endpoints to be exposed") plus an explicit "this constitutes a loss of defence in depth" scoping statement, a Workarounds section, and version tables. [synapse-ghsa-hgcg]
- GHSA-cjh7-rcpx-xpf8 similarly states impact, exact threat model, and non-affected configurations in plain language: "Local authenticated users that are conspiring with, or tricked by, a malicious federated homeserver can cause room aliases to have their destination room changed... Homeservers that do not federate or only participate in a closed, trusted federation are not affected." [synapse-ghsa-cjh7]
- Synapse's CONTRIBUTING guide mandates a separate towncrier changelog fragment (`changelog.d/<PR>.bugfix` etc.) for every PR, written "in the same style as the rest of the changelog," distinct from the git commit message — this is the documented, required location for the reader-facing description, not the commit. [synapse-contributing-changelog]
- A real merged Synapse bugfix changelog fragment reads as one plain sentence naming the failure mode and trigger condition: "Fix a bug where presence updates could stop being sent to clients (the presence stream position becoming stuck) if a `/sync` request was cancelled while a presence write was allocating a stream ID." [synapse-changelog-fragment-20090]
- Nextcloud's actual security-fix PR #60884 ("fix(TaskProcessing): restrict allowed_classes in Manager cache deserialization") has a PR body that is a strong example of outsider-legible security-fix prose: it names the exact code line, explains the vulnerability class in plain terms ("An attacker who can write to the cache backend (e.g., Redis without authentication or with weak ACLs — a common misconfiguration in cloud deployments) can inject a PHP gadget chain and achieve Remote Code Execution via PHP Object Injection"), shows before/after code, and cites the same defensive pattern already used elsewhere in the codebase (`FileProfilerStorage`, `CommandJob`, `QueueBus`) as precedent. [nextcloud-pr-60884]
- Nextcloud's CONTRIBUTING.md formally requires Conventional Commits format for commit messages (example given: `feat(files_sharing): allow sharing with contacts`) and separately requires an `Assisted-by: AGENT_NAME:MODEL_VERSION` git trailer plus PR-description disclosure whenever AI assistance was used, distinguishing that disclosure from the DCO `Signed-off-by` trailer. [nextcloud-contributing-conventional-commits]
- Vaultwarden's merged PR #7061 ("Reject unrecognised DATABASE_URL instead of silent SQLite fallback") has a commit body that is a genuinely clear, self-contained plain-language explanation of a real-world privacy/data-loss bug for a password manager, without needing an external advisory: it states the prior silent behavior, names the concrete user-facing consequence ("This caused data loss in containerised environments when the URL was misconfigured... vaultwarden would create an ephemeral SQLite database that was wiped on restart"), and states the new behavior. [vaultwarden-pr-7061]
- Contrast/bad example: Vaultwarden's merged PR #7558, titled only "Misc fixes and updates," bundles at least four unrelated changes (CI/pre-commit config update, an admin-diagnostics template-override check, an eslint config fix, and a cipher-collection-update fix) under one opaque squash title with no changelog-style summary — a reader scanning `git log` gets zero signal about what actually changed. [vaultwarden-pr-7558-bad]
- Contrast/bad example: Standard Notes's merged PR #3029, titled "fix: Fixes hardware key authentication," has an empty PR body (`"body":null`) and a commit title that says a bug existed and was fixed but never states what was broken, why, or what the fix does — for a security-relevant authentication code path, this gives an outside reader no way to assess whether the underlying issue mattered to them. [standardnotes-pr-3029-bad]

## SOURCES

**synapse-ghsa-hgcg**
URL: https://github.com/element-hq/synapse/security/advisories/GHSA-hgcg-p9gx-fq5f
Accessed: 2026-08-14
Quote: "On some endpoints, Synapse will accept extraneous (suffix) data on the path of some endpoints. When Synapse is protected by a reverse proxy (such as Nginx) and the reverse proxy normalises paths when routing... this can lead to a bypass of reverse proxy rules, allowing unintended endpoints to be exposed. This constitutes a loss of defence in depth."

**synapse-ghsa-cjh7**
URL: https://github.com/element-hq/synapse/security/advisories/GHSA-cjh7-rcpx-xpf8
Accessed: 2026-08-14
Quote: "Local authenticated users that are conspiring with, or tricked by, a malicious federated homeserver can cause room aliases to have their destination room changed. Homeservers that do not federate or only participate in a closed, trusted federation are not affected."

**synapse-contributing-changelog**
URL: https://github.com/element-hq/synapse/blob/develop/docs/development/contributing_guide.md
Accessed: 2026-08-14
Quote: "All changes, even minor ones, need a corresponding changelog / newsfragment entry. These are managed by Towncrier. ... the content of the file should be a short description of your change in the same style as the rest of the changelog."

**synapse-changelog-fragment-20090**
URL: https://raw.githubusercontent.com/element-hq/synapse/develop/changelog.d/20090.bugfix
Accessed: 2026-08-14
Quote: "Fix a bug where presence updates could stop being sent to clients (the presence stream position becoming stuck) if a `/sync` request was cancelled while a presence write was allocating a stream ID. Contributed by @FrenchGithubUser @Famedly."

**nextcloud-pr-60884**
URL: https://github.com/nextcloud/server/pull/60884
Accessed: 2026-08-14
Quote: "The serialized data contains `ShapeDescriptor` objects... An attacker who can write to the cache backend (e.g., Redis without authentication or with weak ACLs — a common misconfiguration in cloud deployments) can inject a PHP gadget chain and achieve Remote Code Execution via PHP Object Injection. ... Nextcloud already uses `allowed_classes` in `FileProfilerStorage`, `CommandJob`, and `QueueBus` — this PR extends the same pattern to `TaskProcessing\\Manager`."

**nextcloud-contributing-conventional-commits**
URL: https://github.com/nextcloud/server/blob/master/CONTRIBUTING.md
Accessed: 2026-08-14
Quote: "Please use Conventional Commits for your commit messages... `feat(files_sharing): allow sharing with contacts`" and "Declare AI tool use in the PR description and add an `Assisted-by: AGENT_NAME:MODEL_VERSION` git trailer to each affected commit."

**vaultwarden-pr-7061**
URL: https://github.com/dani-garcia/vaultwarden/commit/54895ad4be
Accessed: 2026-08-14
Quote: "Previously, any DATABASE_URL that did not match the mysql: or postgresql: prefix was silently treated as a SQLite file path. This caused data loss in containerised environments when the URL was misconfigured (typos, quoting issues), as vaultwarden would create an ephemeral SQLite database that was wiped on restart."

**vaultwarden-pr-7558-bad**
URL: https://github.com/dani-garcia/vaultwarden/commit/b30cc08562
Accessed: 2026-08-14
Quote: "Misc fixes and updates (#7558)" (title); body bundles "Update GHA and pre-commit", "Update admin diagnostics", "Fix org import", "deduplicate send validation" under one commit with no per-change summary line.

**standardnotes-pr-3029-bad**
URL: https://github.com/standardnotes/app/pull/3029
Accessed: 2026-08-14
Quote: `{"body":null,"title":"fix: Fixes hardware key authentication"}` (via `gh api repos/standardnotes/app/pulls/3029`)

## SYNTHESIS

The peer group does NOT converge on "put the explanation in the commit message." They converge on
"put the explanation somewhere a reader will actually find it," and for the most disciplined projects
(Synapse, Nextcloud) that place is structurally separate from the commit: a towncrier changelog
fragment (Synapse), a public GHSA advisory (Synapse, for anything CVE-worthy), or the PR description
(Nextcloud, Vaultwarden). The commit title stays short and mechanical; the "why this matters to an
outside reader" prose lives one level up, in a place with its own required format and its own review
gate. This matters for PDP-Connect because Tim's existing standing rule ("PR descriptions stay
concise... audit trails go in commit messages, not PR bodies") is the *inverse* emphasis of what
Synapse/Nextcloud actually practice for security-sensitive changes — worth flagging as a real tension,
not a contradiction to silently resolve. The peer-group pattern suggests: commit titles should name the
defect precisely (as Synapse's do — "path traversal", "room alias theft" — these are good, specific,
plain-language titles even without body prose), and a structured location (PR body or, if PDP-Connect
ever adds one, a changelog-fragment convention) should carry the "attacker capability + user-facing
consequence + why we consider this a real risk" explanation, per Nextcloud's PR #60884 as the strongest
found example of that structure.

The two bad-contrast examples are useful calibration for what NOT to do, and both are ordinary,
frequent failure modes rather than rare accidents: an opaque squash-merge title ("Misc fixes and
updates") that hides multiple unrelated changes behind one non-descriptive commit, and a PR with a
present-tense fix title but literally empty body on an authentication code path. Neither project is
uniformly disciplined — Synapse and Nextcloud earn their reputation through an enforced *process*
(towncrier gate, Conventional Commits convention), not universal commit-message quality; Vaultwarden
and Standard Notes have no published, enforced convention and their history shows it.

Nextcloud's AI-disclosure trailer (`Assisted-by: AGENT_NAME:MODEL_VERSION`, distinct from
`Signed-off-by`) is close prior art for Tim's own `Assisted-by: AI` convention (per
`~/code/dotfiles/ai/AGENTS.md`) — Nextcloud's version is more specific (names agent + model), which is
a stronger, more auditable pattern worth considering if PDP-Connect ever formalizes this beyond a
single line.
