---
title: "GitHub push protection is free and default-on for public repos but costs $19/active-committer/month on private ones, and is self-service bypassable unless delegated bypass is configured"
date: 2026-08-07
topic: repo-hygiene-and-secret-scanning
tags: [github, secret-scanning, push-protection, ghas, pricing, rollout]
status: draft
sources: [ghas-billing, about-push-protection, about-secret-scanning, unbundle-changelog, team-plan-changelog, buy-advanced-security, security-configurations, filter-repositories, phase-6-rollout, delegated-bypass, secret-risk-assessment]
source_session: 02d16fad-5b89-4da2-bcfc-53ef8471d46c
---

## CLAIMS

- Public repositories get secret scanning, code scanning, and dependency review at no charge on any plan. [ghas-billing]
- Push protection is free for public repositories and enabled by default for users; it "stops you from pushing secrets to public repositories on GitHub" without a license. [about-push-protection]
- Private and internal repositories require a paid GitHub Secret Protection license for both secret scanning and push protection; repo-level push protection "is disabled by default" there. [about-secret-scanning] [about-push-protection]
- On 2025-04-01 GHAS was unbundled into **Secret Protection** ($19/active committer/month) and **Code Security** ($30/active committer/month), and became purchasable by **GitHub Team** orgs for the first time — previously Enterprise-only. [unbundle-changelog] [team-plan-changelog] [buy-advanced-security]
- A committer bills as "active" if one of their commits was pushed within the last **90 days** to a repo where the paid feature is *enabled*, regardless of original authorship date. Bots (GitHub App commits) are excluded. Usage is deduplicated org-wide. [ghas-billing]
- Enabling the features on public repos alone incurs **zero** cost, because public repos are free regardless of plan. [ghas-billing]
- **Security configurations** are the current recommended org-wide rollout mechanism, replacing per-repo `PATCH /repos/{owner}/{repo}` `security_and_analysis` calls. [security-configurations]
- Configurations support subset targeting by visibility (public/private/internal) plus name search and hand-picked selection. [filter-repositories]
- "Default for new repositories" applies only to *newly created* repos — repos **transferred into** the org still need manual configuration. [github-recommended-config]
- Enforcing a configuration "blocks repository owners from changing features that are enabled or disabled by the configuration"; features left unset remain repo-owner-editable. [security-configurations]
- Configurations apply to archived repos by default, "because some security features run on archived repositories, for example, secret scanning." [security-configurations]
- GitHub's documented rollout order is: free Secret Risk Assessment → secret scanning **alerts** across all repos → push protection **second** → remediate backlog with ownership pushed to the team owning each repo → then expand to custom patterns. Blocking is explicitly not step one. [phase-6-rollout] [secret-risk-assessment]
- On first enablement, secret scanning "scans your entire Git history on all branches" — not just new commits. [about-secret-scanning]
- Push protection blocks only **new** pushes; already-committed secrets need separate remediation (revoke/rotate at source; history rewriting is insufficient alone since the secret may already be cloned or forked). [about-secret-scanning]
- **By default anyone with write access can bypass a block** by selecting a reason ("used in tests" / "false positive" / "will fix later"). Bypasses create an alert, write an audit-log event, and email repo/org admins. [about-push-protection]
- **Delegated bypass** (beta as of this research) restricts bypass to specified roles/teams and routes everyone else through request-and-approval; org-level settings override repo-level when both are set. This is what converts push protection from a log-and-notify speed bump into a hard gate. [delegated-bypass]
- The free **Secret Risk Assessment** is a point-in-time scan across all public and private repos requiring no license, available to Team plan. [secret-risk-assessment]
- Forks inherit push protection from any ancestor in the fork chain (2026 change); previously a fork could dodge upstream protection. [pattern-updates-2026]

## SOURCES

**ghas-billing**
URL: https://docs.github.com/en/billing/concepts/product-billing/github-advanced-security
Accessed: 2026-08-07
Quote: "All public repositories have access to code scanning, secret scanning, and dependency review"

**about-push-protection**
URL: https://docs.github.com/en/code-security/introduction/about-push-protection
Accessed: 2026-08-07
Quote: "stops you from pushing secrets to public repositories on GitHub"

**about-secret-scanning**
URL: https://docs.github.com/en/code-security/introduction/about-secret-scanning
Accessed: 2026-08-07
Quote: "scans your entire Git history on all branches of your repository for hardcoded credentials"

**unbundle-changelog**
URL: https://github.blog/changelog/2025-03-04-introducing-github-secret-protection-and-github-code-security/
Accessed: 2026-08-07
Quote: "these products will become available to GitHub Team plan customers for the first time"

**team-plan-changelog**
URL: https://github.blog/changelog/2025-04-01-github-advanced-security-is-here-for-github-team-organizations/
Accessed: 2026-08-07
Quote: "GitHub Advanced Security is here for GitHub Team organizations"

**buy-advanced-security**
URL: https://docs.github.com/en/billing/how-tos/products/buy-advanced-security
Accessed: 2026-08-07
Quote: "GitHub Team or GitHub Enterprise"

**security-configurations**
URL: https://docs.github.com/en/code-security/securing-your-organization/introduction-to-securing-your-organization-at-scale/choosing-a-security-configuration-for-your-repositories
Accessed: 2026-08-07
Quote: "blocks repository owners from changing features that are enabled or disabled by the configuration"

**filter-repositories**
URL: https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/manage-your-coverage/filter-repositories
Accessed: 2026-08-07
Quote: visibility filter (public/private/internal) plus free-text/name search

**github-recommended-config**
URL: https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/establish-complete-coverage/applying-the-github-recommended-security-configuration-in-your-organization
Accessed: 2026-08-07
Quote: applies to newly created repositories, not repositories transferred into the organization

**phase-6-rollout**
URL: https://docs.github.com/en/enterprise-server@3.18/code-security/adopting-github-advanced-security-at-scale/phase-6-rollout-and-scale-secret-scanning
Accessed: 2026-08-07
Quote: "Once you have enabled secret scanning, you should also enable push protection."

**delegated-bypass**
URL: https://docs.github.com/en/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/delegated-bypass-for-push-protection
Accessed: 2026-08-07
Quote: restricts who can bypass and routes others through a request-and-approval workflow

**secret-risk-assessment**
URL: https://docs.github.com/en/code-security/securing-your-organization/understanding-your-organizations-exposure-to-leaked-secrets/about-secret-risk-assessment
Accessed: 2026-08-07
Quote: point-in-time scan across public and private repositories, no license required

**pattern-updates-2026**
URL: https://github.blog/changelog/2026-04-14-secret-scanning-pattern-updates-and-product-improvements/
Accessed: 2026-08-07
Quote: forks inherit push protection from any ancestor in the fork chain

## SYNTHESIS

The practical upshot for any org deciding whether "turn on push protection" is an afternoon or a procurement cycle: **it's both, split by repo visibility.** Public repos are free and should already be on — if they show `disabled`, someone turned them off or an org default overrode them, and that's worth investigating rather than assuming the default held. Private repos are a real recurring bill: at $19/active committer with a 90-day rolling window, a 15–20 person eng org lands around $285–380/month.

Two traps worth remembering:

1. **"Purchased: Unlimited licenses" in the org GHAS panel means unlimited *available*, not free.** The per-committer meter starts when you enable the feature on private repos. Read the Licensing usage page after enabling rather than trusting an estimate.

2. **Default push protection is not a control, it's a notification.** Anyone with write access clicks through with a reason. Any policy document that says "blocked at push" needs delegated bypass configured to be true — otherwise the honest description is "blocked unless the pusher chooses otherwise, with an audit trail."

The docs' phased order (assessment → alerts → blocking → remediate) exists because first enablement scans full git history on all branches, so a repo estate with years of history and nothing enabled produces a backlog *before* anyone is blocked. Turning on blocking first means developers hit walls for secrets that predate the rollout.

Gap worth noting: no authoritative source gives expected alert-backlog volume for a given repo count. The free Secret Risk Assessment exists precisely to answer that with real numbers, so run it rather than estimating — and it doubles as the budget justification for the private-repo spend.
