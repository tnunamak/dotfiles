---
title: "No industry-named pattern exists for CI inferring absent local pre-commit hooks purely from its own scan findings, but vendors (GitGuardian, Gitleaks/community) universally frame pre-commit + CI as preventive-vs-compensating/mandatory-enforcement layers with an explicit bypassability rationale; git signing, notes, and push-options are used for identity/CI-control, never as machine-configuration-compliance proxies; SLSA/SSDF name developer-endpoint requirements only loosely; MDM-enforced core.hooksPath has no found real-world example"
date: 2026-08-10
topic: secret-scanning-drift-detection
tags: [secret-scanning, pre-commit, ci-cd, compensating-control, slsa, ssdf, git-hooks, mdm, config-drift]
status: draft
sources: [gitguardian-hooks-glossary, decryption-digest-prevent-secrets, dev-to-gitleaks-precommit-ci, elegant-software-gitleaks, slsa-verified-history, cycode-slsa-source, nist-ssdf-secportal, aikido-nist-ssdf, git-scm-push-options, gitlab-push-options-doc, git-scm-githooks, brandon-pugh-hookspath, git-scm-commit-template, ggshield-pypi]
source_session: debe0ad9-1dea-4c76-acfc-16afb45a7c87
---

## CLAIMS

- No source uses a specific named term ("differential detection," "shift-left drift detection") for the inference "CI's own scan finding a secret IS the proof the local pre-commit hook was absent/misconfigured." This exact inferential framing was not found under any name. [gitguardian-hooks-glossary][dev-to-gitleaks-precommit-ci]
- Vendors and practitioner blogs universally frame pre-commit hooks as the **preventive** layer and CI/pre-receive/push-protection as the **compensating/mandatory-enforcement** layer, with the explicit stated rationale being bypassability: pre-commit hooks can be skipped with `git commit --no-verify`, so CI is needed as a layer that "cannot be bypassed by developers." [dev-to-gitleaks-precommit-ci][decryption-digest-prevent-secrets]
- GitGuardian's own tooling (ggshield) documents itself as running in the same modes across local pre-commit and CI, explicitly naming CI as a "mandatory enforcement layer" precisely because it "cannot be bypassed." [ggshield-pypi][gitguardian-hooks-glossary]
- Multiple sources (elegantsoftwaresolutions, secure-pipelines.com) describe pre-commit hooks catching "95% of cases" locally with CI catching "the rest" — a quantified complementary-layers claim, though the 95% figure is asserted without a cited study, so it reads as practitioner folklore rather than measured data. [elegant-software-gitleaks]
- `git commit.template` is documented by git-scm.com and multiple blogs as purely advisory/local — it pre-fills an editor and is explicitly not synced or enforced across machines; no source treats it as an enforcement or compliance-detection mechanism. [git-scm-commit-template]
- No source treats `user.signingkey` presence, or commit-signing status generally, as a proxy for "this machine is properly configured" (a configuration signal). All sources found frame signing purely as an authorship/identity and non-repudiation control, verified server-side via an "allowed signers" file mapping keys to people, not machines-as-configured. [git-scm-githooks (indirectly)]
- One tangential machine-identity practice was found: some individual developers generate one SSH signing key per machine (so a key never leaves its origin machine), which lets an observer infer *which machine* produced a signed commit — but no source extends this to "and therefore that machine's hooks/config were compliant." This is inference, not a documented practice. [none — reasoned from search synthesis, not a citable source]
- `git push -o` / `--push-option` is real and documented: values are passed to server-side pre-receive/post-receive hooks via `GIT_PUSH_OPTION_n` env vars. GitLab supports arbitrary custom push options being routed to server-side hooks. Documented real uses are narrow: GitLab's built-in `ci.skip` (skip pipeline) and `merge_request.create/target` (MR automation). [git-scm-push-options][gitlab-push-options-doc]
- No real example was found of push options, git notes, or a pre-push hook being used to "register" that a machine/clone is properly configured for compliance purposes, at GitLab, GitHub, or any company engineering blog. This appears to be an unbuilt pattern, not a hidden/obscure one — search across multiple phrasings turned up only generic hook tutorials. [gitlab-push-options-doc]
- SLSA's Source track (v1.0) requires "verified history" (strongly authenticated actor identity + timestamp per change, 2FA on identities, retained ≥18 months) and, at higher levels, two-person review — but these apply to the **source control platform's** record-keeping, not to developer workstation/endpoint tooling. [slsa-verified-history][cycode-slsa-source]
- SLSA explicitly excludes developer workstations from qualifying as a **build** environment ("running builds on developers' workstations does not qualify as a build service") — this is a build-track exclusion, not an endpoint-hardening requirement, and is often conflated with the latter. [cycode-slsa-source]
- NIST SSDF (SP 800-218) PO.1.1 requires organizations to "identify and document security requirements for software development infrastructures," explicitly naming "development endpoints" as in-scope — but SSDF is deliberately outcome-based and does not name pre-commit hooks or any specific tool/mechanism as a required control. [nist-ssdf-secportal][aikido-nist-ssdf]
- No CIS benchmark, SLSA requirement ID, or SSDF practice ID was found that names "verify pre-commit hook installation" specifically as a requirement. [nist-ssdf-secportal]
- `core.hooksPath` is a real, documented Git feature (since Git 2.9, 2016) for pointing a repo at a shared/version-controlled hooks directory — used commonly for team-shared hooks (e.g., an `.githooks/` dir checked into the repo). [brandon-pugh-hookspath][git-scm-githooks]
- No real company blog or docs example was found of MDM (Jamf/Kandji/Intune) being used specifically to push/enforce a `core.hooksPath` git config value as an organization-wide mandatory-hooks mechanism. MDM-pushed policy examples that were found (e.g., Claude Code's own managed-settings.json via Jamf/Kandji/Intune plist/registry) are a structurally identical pattern applied to a different tool, not the git-hooks case itself. [none directly — see eesel-ai claude-code-admin-controls found in search, not saved as its own slug since off-topic for this corpus]

## SOURCES

**gitguardian-hooks-glossary**
URL: https://www.gitguardian.com/glossary/git-hooks
Accessed: 2026-08-10

**decryption-digest-prevent-secrets**
URL: https://www.decryptiondigest.com/blog/prevent-developers-pushing-secrets-git-pre-commit-gitleaks-guide
Accessed: 2026-08-10

**dev-to-gitleaks-precommit-ci**
URL: https://dev.to/sirlawdin/secret-scanning-in-ci-pipelines-using-gitleaks-and-pre-commit-hook-1e3f
Accessed: 2026-08-10

**elegant-software-gitleaks**
URL: https://www.elegantsoftwaresolutions.com/blog/gitleaks-pre-commit-hooks-stop-leaks-before-push
Accessed: 2026-08-10

**slsa-verified-history**
URL: https://slsa.dev/spec/v1.0/source-requirements (via search synthesis; also see cycode-slsa-source)
Accessed: 2026-08-10

**cycode-slsa-source**
URL: https://cycode.com/blog/slsa-source-requirements/
Accessed: 2026-08-10
Quote: "running builds on developers' workstations does not qualify as a build service"

**nist-ssdf-secportal**
URL: https://secportal.io/blog/nist-ssdf-implementation-guide
Accessed: 2026-08-10

**aikido-nist-ssdf**
URL: https://www.aikido.dev/learn/compliance/compliance-frameworks/nist-ssdf
Accessed: 2026-08-10

**git-scm-push-options**
URL: https://git-scm.com/docs/git-push
Accessed: 2026-08-10

**gitlab-push-options-doc**
URL: https://docs.gitlab.com/user/project/push_options/ (also https://gitlab.com/gitlab-org/gitlab/-/issues/18049)
Accessed: 2026-08-10

**git-scm-githooks**
URL: https://git-scm.com/docs/githooks
Accessed: 2026-08-10

**brandon-pugh-hookspath**
URL: https://www.brandonpugh.com/til/git/config-hookspath/
Accessed: 2026-08-10

**git-scm-commit-template**
URL: https://git-scm.com/docs/git-commit/2.10.5
Accessed: 2026-08-10

**ggshield-pypi**
URL: https://pypi.org/project/ggshield/1.10.0/
Accessed: 2026-08-10

## SYNTHESIS

For the 9-person team's actual design problem (CI detecting hook-drift from its own re-scan findings), there is no existing named pattern or vendor writeup to cite as precedent — this would be a novel-but-reasonable design, not a reinvention of something already documented. The closest existing industry framing is the preventive-vs-compensating-control language used by GitGuardian/Gitleaks/community writeups, which independently justifies running both layers (bypassability of pre-commit, need for a layer that "cannot be bypassed") — that framing supports the team's CI-side re-scan but does NOT itself describe using scan findings as *evidence of absence* of the local hook. The team's idea is a step further than what the industry currently writes about: existing sources treat CI as a backstop that catches what slipped through, not as a diagnostic that infers *why* something slipped through (hook missing vs. hook present-but-imperfect vs. secret type hook doesn't cover). Worth flagging to the team: a CI finding is consistent with several causes (no hook, out-of-date hook/ruleset, hook installed but bypassed with `--no-verify`, or a secret pattern the local hook's ruleset simply doesn't cover yet) — treating "finding = hook absent" as a tripwire will have false positives against those other causes, and no vendor source resolves this ambiguity because none of them make the inferential leap the team is proposing.

The config-proxy ideas (signing key presence, commit.template, notes, push-options) are all real Git mechanisms but none are used in the wild as configuration-compliance signals — they're used for identity/authorship (signing), convenience (template), or CI/MR control (push-options). If the team wants a "prove the hook ran" signal rather than an inferred one, the only real, shipped mechanism that structurally fits is `core.hooksPath` pushed via MDM (sidestepping detection entirely by making the hook non-optional) — but no company has published this specific combination; it would need to be built by analogy to how Jamf/Kandji/Intune already push other tool configs (e.g., Claude Code's managed-settings.json), which IS a real, documented pattern for a different tool.
