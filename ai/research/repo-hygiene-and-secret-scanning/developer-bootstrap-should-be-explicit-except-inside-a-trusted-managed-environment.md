---
title: "Developer bootstrap should be explicit except inside a trusted managed environment because Git cannot activate tracked hooks and package managers are restricting install-time execution"
date: 2026-08-12
topic: repo-hygiene-and-secret-scanning
tags: [developer-setup, git-hooks, npm, pnpm, yarn, mise]
status: draft
sources: [git-hooks, git-init, npm-v12-scripts, pnpm-approve-builds, yarn-lifecycle, yarn-security, husky-how-to, pre-commit, mise-trust, github-codespaces]
source_session: unknown
---

## CLAIMS

- Git executes hooks from `$GIT_DIR/hooks` or `core.hooksPath`. A repository can track hook source, but tracked files do not become active hooks by themselves. Git templates can copy hooks during clone or init only after a user or administrator configures the template. [git-hooks][git-init]
- npm 12 has project-level approval policy for dependency install scripts. npm's documentation directs teams to record reviewed dependencies in `allowScripts`; `strict-allow-scripts` can make an unreviewed dependency script fail installation. Root project lifecycle scripts still exist, but `prepare` also runs during `npm ci`, packing, publishing, local installation, and some Git dependency installs. [npm-v12-scripts]
- pnpm 10 requires explicit approval for dependency build scripts and records approvals in project configuration. [pnpm-approve-builds]
- Yarn deliberately supports fewer implicit lifecycle hooks and says postinstall scripts should be avoided because they make installation slower and riskier. Yarn 4.14 and later do not run postinstall scripts by default unless scripts are enabled globally or for a package. [yarn-lifecycle][yarn-security]
- Husky recommends a `prepare` script for automatic installation after npm or pnpm installs, but documents separate CI and production guards. For Yarn, Husky uses `postinstall` and recommends `pinst` for published packages. [husky-how-to]
- pre-commit requires `pre-commit install` after clone by default. It can configure a user-level Git template to activate hooks in future clones, but warns against globally enabling arbitrary repository hooks because an untrusted repository can then execute code. [pre-commit]
- mise requires trust before it evaluates configuration that can execute code. A safe configuration that contains plain tool versions and non-templated tasks can be read without a prompt, but tools and tasks still run only through explicit commands such as `mise install` and `mise run`. [mise-trust]
- GitHub recommends dev-container lifecycle commands such as `postCreateCommand` for setup that must occur after a repository has been cloned into a Codespace. This is automatic inside that selected managed environment, not for arbitrary local clones. [github-codespaces]

## SOURCES

**git-hooks**
URL: https://git-scm.com/docs/githooks
Accessed: 2026-08-12

**git-init**
URL: https://git-scm.com/docs/git-init
Accessed: 2026-08-12

**npm-v12-scripts**
URLs:
- https://docs.npmjs.com/cli/v12/using-npm/scripts/
- https://docs.npmjs.com/cli/install/
Accessed: 2026-08-12

**pnpm-approve-builds**
URL: https://pnpm.io/cli/approve-builds
Accessed: 2026-08-12

**yarn-lifecycle**
URL: https://yarnpkg.com/advanced/lifecycle-scripts
Accessed: 2026-08-12
Quote: "Postinstall scripts should be avoided at all cost, as they make installs slower and riskier."

**yarn-security**
URL: https://yarnpkg.com/features/security
Accessed: 2026-08-12

**husky-how-to**
URLs:
- https://typicode.github.io/husky/get-started.html
- https://typicode.github.io/husky/how-to.html
Accessed: 2026-08-12

**pre-commit**
URL: https://pre-commit.com/
Accessed: 2026-08-12

**mise-trust**
URLs:
- https://mise.jdx.dev/getting-started.html
- https://mise.jdx.dev/cli/trust.html
Accessed: 2026-08-12

**github-codespaces**
URL: https://docs.github.com/en/codespaces/about-codespaces/deep-dive
Accessed: 2026-08-12

## SYNTHESIS

No repository can safely activate its own Git hooks on an arbitrary local clone without one prior trusted action. Hiding that action in `postinstall` or `prepare` reduces onboarding friction for one package manager, but it also couples a Git mutation to dependency installation, runs in CI and packaging contexts unless guarded, and becomes inconsistent when users disable lifecycle scripts. The 2026 package-manager direction makes this less reliable over time: npm and pnpm add script approval, while Yarn disables postinstall by default and advises against it.

Use one explicit, idempotent repository bootstrap command as the portable contract. Package scripts and mise tasks should be aliases to that command, not separate implementations. Put the command in the first setup block and make a missing hook fail with a direct remediation message when a developer first pushes. Keep CI as the mandatory backstop because any client hook remains bypassable.

For a managed development environment, run the same bootstrap command from the environment's post-create lifecycle. This provides automatic setup without pretending that arbitrary local clones have consented to execute repository code. Organization-managed Git templates can also activate a dispatcher in every new clone, but they require a one-time workstation policy installation and must not execute arbitrary repository configuration without an explicit allowlist.

For the current Vana rollout, retain the explicit setup commands. Do not add `postinstall` to the Yarn repositories or add another package-manager lifecycle to the SDK. The SDK's existing Husky `prepare` can install the tracked Husky dispatcher during `npm install`, but preparing the pinned scanner should remain an explicit setup action unless Vana adopts a managed dev environment. For node-ops, keep `mise trust && mise run setup`. For `vana` and `vana-chain-forensics`, keep the checked-in setup script rather than introducing Node solely for hook installation.
