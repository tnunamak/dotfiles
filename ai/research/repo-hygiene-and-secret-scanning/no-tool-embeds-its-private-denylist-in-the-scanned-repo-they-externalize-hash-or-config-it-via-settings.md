---
title: "No major secret-scanning/hygiene tool embeds its private denylist inside the scanned repo — gitleaks/trufflehog externalize config via env var or --config, detect-secrets hashes rather than storing plaintext, GitHub keeps custom patterns in settings UI outside the tree, and none of them document or endorse a scanner exempting its own definition file from its own scan"
date: 2026-08-03
topic: repo-hygiene-and-secret-scanning
tags: [secret-scanning, gitleaks, trufflehog, detect-secrets, git-secrets, github-secret-scanning, pre-publication-hygiene, public-mirror, bfg, git-filter-repo, self-exempting-scanner]
status: settled
sources: [gitleaks-readme-config-precedence, gitleaks-issue-1557, gitlab-secret-detection-central-ruleset, git-secrets-manpage, git-secrets-readme, detect-secrets-design-doc, detect-secrets-readme, trufflehog-custom-detectors-docs, trufflehog-enterprise-locally-configured-detectors, github-custom-patterns-docs, github-custom-patterns-limits, sec-gov-oss-policy, gsa-oss-policy, bfg-repo-cleaner-site, git-filter-repo-readme, github-community-discussion-155997]
source_session: unknown
---

## CLAIMS

### A. How the established tools separate engine from ruleset

**gitleaks**
- Config precedence, quoted from the gitleaks README: "The order of precedence is: 1. `--config/-c` option 2. Environment variable `GITLEAKS_CONFIG` with the file path 3. Environment variable `GITLEAKS_CONFIG_TOML` with the file content 4. A `.gitleaks.toml` file within the target path[.] If none of the four options are used, then gitleaks will use the default config." [gitleaks-readme-config-precedence]
- A config can **fully replace** default rules ("define your own configuration, default rules do not apply") or **extend** them via `[extend]` with `useDefault = true` or a path to another config to extend from; on overlap, "the extended rules or attributes of them will override the default rules." [gitleaks-readme-config-precedence]
- Rule-level allowlisting uses `[[rules.allowlists]]`; a top-level `[[allowlists]]` block has "a higher order of precedence than rule-specific allowlists." [gitleaks-readme-config-precedence]
- `GITLEAKS_CONFIG` (a file path) and `GITLEAKS_CONFIG_TOML` (literal file contents) are both environment-variable mechanisms, meaning a private ruleset never has to be a tracked file in the scanned repo at all — it can be injected purely at scan time. [gitleaks-issue-1557]
- The `--config` flag does not support fetching a config from a remote URL; teams that want a centrally-maintained private ruleset shared across many repos work around this by fetching the file first (a wrapper script, or a platform-native mechanism) and pointing `--config` at the local copy. [gitleaks-issue-1557]
- GitLab's Secret Detection analyzer (which shells out to a gitleaks-compatible ruleset) documents exactly this "centrally maintained, externally hosted ruleset" pattern natively: "the remote ruleset configuration file is called `gitleaks.toml`, and is stored in [a] `config` directory on the main branch of the referenced [central] repository" and individual projects "include" that repo's ruleset rather than duplicating it, with the option to locally override/disable a specific inherited rule. [gitlab-secret-detection-central-ruleset]
- Gitleaks is explicitly in maintenance mode: "feature complete, with no new features being merged — future releases will be security patches only" (per project status note), so the above precedence/extension mechanics are stable but will not gain new capabilities. [gitleaks-issue-1557]

**git-secrets (awslabs)**
- `git secrets --add-provider [--global] <command> [args...]` registers an external command whose stdout (prohibited patterns, one per line) is used as the pattern source, rather than requiring patterns to sit in a tracked file. [git-secrets-manpage]
- Without `--global`, provider registration and pattern config are written to the **current repository's** `.git/config` — which is never itself a tracked/committed file — so per-repo config is local-machine-only by construction. [git-secrets-manpage]
- With `--global`, the same config is written to `~/.gitconfig` instead, applying across every repo on the machine; a documented workflow pairs this with a git template directory (`git config --global init.templateDir ~/.git-templates/git-secrets`) so every newly-cloned repo inherits the hook and the global pattern set automatically. [git-secrets-readme]
- This is a structural design choice, not an incidental one: git-secrets stores *no* pattern data inside any file that git itself would ever track or diff, by using git's own config plumbing (which is deliberately excluded from version control) as the pattern store. [git-secrets-manpage]

**detect-secrets (Yelp)**
- The `.secrets.baseline` file is a JSON document that records, per finding, a **hash** of "the actual secret, the filepath where it was found, [and] how the engine determined it was a secret" — not the plaintext value. [detect-secrets-design-doc]
- This is what makes the baseline safe to commit: reviewers can audit/label findings (true positive vs. false positive) via the `audit` command, and those labels persist across re-scans, without the baseline file itself ever holding a live credential. [detect-secrets-design-doc][detect-secrets-readme]
- The design doc does **not** explicitly frame this as solving "the detector could itself leak the secret" — hashing is presented as an audit/usability mechanism (safe-to-diff, safe-to-review), not as an articulated threat-model response to that specific tension. This is a documented gap, not an inferred one. [detect-secrets-design-doc]
- Known limitation: hash-based matching still produces false positives against non-secret hash-like strings (e.g., `package-lock.json` SHA1 integrity hashes), which the audit workflow cannot cleanly suppress because those hashes are themselves subject to change. [detect-secrets-design-doc]

**trufflehog**
- Custom detectors are declared in a `config.yaml` with `keywords` (literal string(s) that must appear near a match) plus one or more named `regex` patterns; an optional `verify` block adds a webhook call whose HTTP response code (matched against `successRanges`, default `200`) flips the finding from unverified to verified. [trufflehog-custom-detectors-docs]
- If `verify` is omitted, "all detected secrets will be marked as unverified" — verified/unverified is a per-detector opt-in, not automatic. [trufflehog-custom-detectors-docs]
- TruffleHog's enterprise product supports "locally-configured detectors," i.e., custom detector definitions that live outside the scanned repo/pipeline artifact entirely, at the scanning-infrastructure layer. [trufflehog-enterprise-locally-configured-detectors]
- Note on applicability: trufflehog's verify mechanism targets *credential-shaped* secrets (a regex + a live API call to confirm validity). It has no analog for PDPP's threat model — literal private identifiers (a home path, a hostname, a codename) are not verifiable against any API; "verified/unverified" doesn't transfer to that problem.

**GitHub secret scanning / push protection**
- "A custom pattern can be created in a repository, organization, or enterprise account," configured through Settings → Security → (Advanced) Security → Custom patterns in the GitHub web UI — not through any file inside the repository tree. [github-custom-patterns-docs]
- Organization/enterprise-level custom patterns support up to 500 patterns each; repository-level supports up to 100. [github-custom-patterns-limits]
- Saving a change to a custom pattern closes all alerts raised under the pattern's previous version — patterns are versioned server-side, not file-versioned via git history. [github-custom-patterns-docs]

### B. Whether "the denylist is itself sensitive" is a documented tension, and what's recommended

- No primary source among gitleaks, trufflehog, detect-secrets, git-secrets, or GitHub's docs explicitly frames "the scanner's own ruleset can itself leak the class of thing it's built to catch" as a named design tension with a stated resolution. Each tool's externalization mechanism (env var / git config / hashing / settings UI) is documented as a *config-flexibility* or *audit-usability* feature, not as a response to that specific threat. This is a genuine gap in the primary literature, not something under-researched here. [detect-secrets-design-doc][gitleaks-readme-config-precedence][git-secrets-manpage][github-custom-patterns-docs]
- The closest primary-source acknowledgment of the general shape of the problem is secondary/blog literature (not a tool's own docs) observing that scan-report access "should stay tightly restricted, since the reports themselves contain sensitive data," and that log-scrubbing denylists (e.g., APM/Sentry/Datadog filters) "must themselves reference the secret variable names or patterns," so an exposed filter config can reveal exactly where secrets live. This is analysis-literature, not a tool maintainer's stated design rationale — treat as synthesis-adjacent, not settled fact. [general secondary sources, not corpus-cited as a primary claim]
- Government open-source-release policy is the closest **primary, official** statement of this exact problem for the "public delta"/pre-publication case (not ordinary credential secret-scanning): the U.S. SEC's open source policy states "the project team that releases the code is responsible for scrubbing for sensitive content, such as non-public information, passwords, and other sensitive data," for *every* release, distinct from their internal-only Enterprise GitHub. [sec-gov-oss-policy]
- The U.S. GSA's open-source implementation guide states the identical responsibility model — "the project team that releases the code is responsible for scrubbing for sensitive content" — and separately notes GSA's CTO team built dedicated scripts to help with this scrubbing, treating it as tooling distinct from ordinary CI secret-scanning. [gsa-oss-policy]
- Neither SEC's nor GSA's policy documents where the scrubbing ruleset/checklist itself is allowed to live (public repo vs. internal-only); both describe scrubbing as a **human-owned release gate responsibility**, not an automated in-tree check with a documented storage location for its own patterns.

### C. Pre-publication / squash-to-public workflow (distinct threat model from ordinary secret scanning)

- BFG Repo-Cleaner's documented core use case is exactly literal-string substitution across full git history: "removes all passwords listed in a file... replaced with `***REMOVED***` wherever they occur in your repository," using a caller-supplied file of banned strings (not a tool-embedded list). [bfg-repo-cleaner-site]
- git-filter-repo is positioned as the more general/modern successor and supports operations BFG cannot, e.g. extracting a single subdirectory's history into a standalone repo with renamed paths — the literal "carve one component out for open-sourcing" operation. [git-filter-repo-readme]
- Community guidance (GitHub's own "Cleaning Up Git" discussion) reiterates that history-rewriting tools operate on a throwaway fresh clone by design/convention, and that any commit ever pushed anywhere must be treated as compromised even after history rewrite, because forks/caches/PR references can retain the original blobs by SHA. [github-community-discussion-155997]
- None of BFG, git-filter-repo, or the GitHub discussion ships or recommends a **tracked, in-repo file** of the literal strings to scrub for a specific project — the replacement/banned-string list is treated as caller-supplied, ephemeral, and used only in the rewrite tool's own (untracked, often local-only) invocation. [bfg-repo-cleaner-site][git-filter-repo-readme]

### D. Where such a check should run

- Cross-source consensus (multiple independent guides, not one primary source) converges on a **layered** model for ordinary secret scanning: pre-commit as the fastest/earliest local gate (secrets never leave the developer's machine), pre-push as a lighter-used secondary local gate, and CI as the mandatory backstop specifically because local hooks are bypassable (`--no-verify`), can fail to install, or can silently drift from the CI config. [multiple secondary sources — see note below]
- This layered model is built for **per-commit credential leakage** (the "did someone paste an API key" case). It has no documented analog for PDPP's actual threat model, which is **squash-to-public** — residue enters at the moment a private, full-history repo is condensed into a public delta, not at any single commit in ordinary day-to-day work. No primary source among the reviewed tools' docs discusses hooking a hygiene check specifically into a squash/release/mirror-sync step as opposed to commit/push/CI.

### E. Self-exempting scanners as a named anti-pattern

- No primary source (tool docs, maintainer statement, or named engineering-blog anti-pattern writeup) was found describing "a scanner that excludes its own definition file from its own scan" as a recognized, named anti-pattern. Generic linter exclude-mechanisms (e.g., `golangci-lint` exclude-rules, `.eslintignore`) exist and are commonly used for test fixtures containing intentionally-bad code, but this is a different case (excluding fixtures whose "bad" content is deliberate and safe) from excluding a file that is the **single largest known concentration of the residue class the tool exists to prevent**. This absence of prior art is itself a finding — do not cite an invented consensus here. [searched, not found — negative result]

## SOURCES

**gitleaks-readme-config-precedence**
URL: https://github.com/gitleaks/gitleaks
Accessed: 2026-08-03
Quote: "The order of precedence is: 1. --config/-c option 2. Environment variable GITLEAKS_CONFIG with the file path 3. Environment variable GITLEAKS_CONFIG_TOML with the file content 4. A .gitleaks.toml file within the target path. If none of the four options are used, then gitleaks will use the default config."

**gitleaks-issue-1557**
URL: https://github.com/gitleaks/gitleaks/issues/1557
Accessed: 2026-08-03
Quote: "the --config flag doesn't support remote download" (paraphrased from issue discussion on managing a custom/shared config file)

**gitlab-secret-detection-central-ruleset**
URL: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure/
Accessed: 2026-08-03
Quote: "the remote ruleset configuration file is called gitleaks.toml, and is stored in [a] config directory on the main branch of the referenced repository"

**git-secrets-manpage**
URL: https://github.com/awslabs/git-secrets/blob/master/git-secrets.1
Accessed: 2026-08-03
Quote: "Adds the provider to the global git config. Provider command to invoke. When invoked the command is expected to write prohibited patterns separated by new lines to stdout."

**git-secrets-readme**
URL: https://github.com/awslabs/git-secrets/blob/master/README.rst
Accessed: 2026-08-03
Quote: "Add hooks to all your local repositories. git secrets --install ~/.git-templates/git-secrets git config --global init.templateDir ~/.git-templates/git-secrets"

**detect-secrets-design-doc**
URL: https://github.com/Yelp/detect-secrets/blob/master/docs/design.md
Accessed: 2026-08-03
Quote: "The actual secret, The filepath where it was found, How the engine determined it was a secret" (three hashed attributes recorded per baseline entry)

**detect-secrets-readme**
URL: https://github.com/Yelp/detect-secrets
Accessed: 2026-08-03
Quote: "An enterprise friendly way of detecting and preventing secrets in code."

**trufflehog-custom-detectors-docs**
URL: https://docs.trufflesecurity.com/customizing-detection
Accessed: 2026-08-03
Quote: "unless you run a verification server, secrets found by the custom regex detector will be unverified"

**trufflehog-enterprise-locally-configured-detectors**
URL: https://docs-next.trufflesecurity.com/docs/configuration/detectors/
Accessed: 2026-08-03
Quote: "Locally-configured detectors" (section title; enterprise docs)

**github-custom-patterns-docs**
URL: https://docs.github.com/en/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/custom-patterns/managing-custom-patterns
Accessed: 2026-08-03
Quote: "A custom pattern can be created in a repository, organization, or enterprise account."

**github-custom-patterns-limits**
URL: https://docs.github.com/en/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/custom-patterns/managing-custom-patterns
Accessed: 2026-08-03
Quote: "up to 500 custom patterns for each organization or enterprise account, and up to 100 custom patterns per repository"

**sec-gov-oss-policy**
URL: https://www.sec.gov/about/developer-resources/open-source-policy-implementation
Accessed: 2026-08-03
Quote: "the project team that releases the code is responsible for scrubbing for sensitive content, such as non-public information, passwords, and other sensitive data"

**gsa-oss-policy**
URL: https://open.gsa.gov/oss-implementation/
Accessed: 2026-08-03
Quote: "the project team that releases the code is responsible for scrubbing for sensitive content, including GSA employees and vendors writing custom code, with the CTO team working on scripts to help scrub the code"

**bfg-repo-cleaner-site**
URL: https://rtyley.github.io/bfg-repo-cleaner/
Accessed: 2026-08-03
Quote: "replace all passwords listed in a file with *** REMOVED *** wherever they occur in your repository"

**git-filter-repo-readme**
URL: https://github.com/newren/git-filter-repo
Accessed: 2026-08-03
Quote: "extracting the history of a single directory and renaming all files to have a new leading directory... BFG Repo Cleaner is not capable of this kind of rewrite"

**github-community-discussion-155997**
URL: https://github.com/orgs/community/discussions/155997
Accessed: 2026-08-03
Quote: "almost everyone who does a repository filtering operation does so with a fresh clone"

## SYNTHESIS

**Top-line recommendation for PDPP's `check-public-tree-hygiene.ts`: parameterize — public engine, private ruleset injected at run time via an untracked local file or env var, with the engine itself scanned like any other file (drop the self-exemption).** Concretely:

1. Move the four regex literals (`/home/tnunamak`, `peregrine`, `*.vivid.fish`, `waspflow/<slug>`) out of the committed `.ts` file and into an untracked, gitignored local file (e.g. `.hygiene-patterns.local.json` or an env var `PDPP_HYGIENE_PATTERNS`), loaded at runtime with a safe default of "no patterns" if absent. This is exactly the `GITLEAKS_CONFIG`/`GITLEAKS_CONFIG_TOML` pattern (env var or externally-supplied file path, precedence over any in-tree default) and the git-secrets `--add-provider`/`.git/config` pattern (patterns live in a location git never tracks by construction) — both are real, load-bearing, widely-used mechanisms, not novel to invent here.
2. Once the ruleset is externalized, delete the `p !== SELF_PATH` self-exemption. There is no version of this script left that contains the literals, so there is nothing left for the exemption to protect — and per finding D, no tool or writeup anywhere documents self-exemption as acceptable; it's an unforced anti-pattern once the ruleset is out of the file.
3. Keep the *engine* (the scanning logic, the CLI, the test suite structure) fully public — this matches every reviewed tool's actual choice: gitleaks, trufflehog, detect-secrets, and GitHub secret scanning all ship/document open detection engines; none of them ship the customer's/org's actual private pattern set as part of the public tool.
4. For the specific residue classes here (paths/hostnames/codenames, not credentials), hashing (the detect-secrets approach) is the wrong tool — hashing exists to let a *human* audit whether a *credential* matches a *known* value without re-exposing it; PDPP's literals are not being "allowed once and remembered," they're being permanently forbidden, so a plain externalized denylist (gitleaks/git-secrets style) fits better than a baseline/hash file.
5. Layer it at the right stage: per finding D, ordinary secret scanning is pre-commit/pre-push/CI because the threat is per-commit. PDPP's actual threat is squash-to-public (confirmed recurring per the script's own comment — residue came back once after a prior "residue-zero pass"). That means this check belongs as an explicit, mandatory step in whatever process produces the public squash/mirror-sync (a manual pre-publication gate, matching the SEC/GSA model of "the release team is responsible for scrubbing," which is a human-owned release gate, not a per-commit hook) — running it in lefthook/CI on every commit is fine as a *belt*, but the *suspenders* that actually matters is a required step in the publish/squash procedure itself, since that's the only point the private-literal-in-a-generic-review-comment failure mode (recurrence) actually occurred.

**Strongest single piece of prior art:** the gitleaks configuration precedence chain — `--config` flag → `GITLEAKS_CONFIG` env var (path) → `GITLEAKS_CONFIG_TOML` env var (inline content) → in-tree `.gitleaks.toml` → built-in default — is the cleanest existing proof that "public engine, ruleset supplied out-of-band, in-tree config purely optional/fallback" is a mature, load-bearing, widely-deployed pattern, not something to invent from scratch. GitLab's central shared-ruleset-repo pattern for gitleaks configs is the second-strongest: it shows the *organization-private-but-shared-across-many-repos* case (closer to "one operator's identifiers, many worktrees/checkouts") already has documented tooling support.

**What surprised me / contradicts the framing in the task:**
- The literal claim "the denylist is itself sensitive" as an articulated, named design tension is **not documented anywhere in the primary tool literature** I could find — every tool's externalization mechanism reads as a generic config-flexibility or audit-usability feature, not a stated response to this exact threat. Treat the "canonical answer" framing in the task prompt as this agent's synthesis of independently-documented mechanisms, not a claim any tool's maintainers stated in those terms.
- Similarly, "self-exempting scanner is a known anti-pattern" has **no named prior art** — not a blog post, not a maintainer FAQ, not a static-analysis-tool doc. This is worth flagging back explicitly: the PDPP script's self-exemption isn't violating a documented rule, it's just structurally unforced once the ruleset is externalized (there's nothing left in the public file to protect once step 1 above is done).
- The government open-source-release policies (SEC, GSA) are a better structural match for PDPP's actual problem (pre-publication scrubbing of non-credential residue) than any secret-scanning *tool* is — they explicitly separate an internal-only source-control system from the public release process and assign scrubbing as a named human responsibility of "the project team that releases the code," which is closer to what PDPP needs (a mandatory step in the squash/publish procedure) than a CI secret scanner is. This wasn't the framing I expected going in; I expected the secret-scanning tools to be the closest analog, and instead the closest *procedural* analog turned out to be government/enterprise open-sourcing policy, while the secret-scanning tools were the closest *mechanical* analog (how to externalize a ruleset).
- trufflehog's verified/unverified distinction, which the task asked about explicitly, turned out to be a poor fit for PDPP's problem: it's built for credential-shaped secrets that can be checked against a live API, and has no meaningful analog for "is this home path/hostname/codename currently in the tree" — there's nothing to verify against. Worth not over-indexing on this axis when applying the research.
