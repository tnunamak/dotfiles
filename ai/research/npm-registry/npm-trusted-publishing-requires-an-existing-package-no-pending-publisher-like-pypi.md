---
title: "npm's OIDC trusted-publisher configuration requires the package to already exist on the registry — there is no PyPI-style 'pending publisher' for brand-new package names as of mid-2026"
date: 2026-08-21
topic: npm-registry
tags: [npm, trusted-publishing, oidc, ci-cd, publishing]
status: draft
sources: [npm-docs-trusted-publishers, hn-pypi-designer-comment, setup-npm-trusted-publish-tool, remarkablemark-blog]
source_session: e9cd1c91-05fb-4971-8221-7d939a8f6d71
---

## CLAIMS

- npm's trusted-publisher (OIDC) setup UI lives at `https://www.npmjs.com/package/${packageName}/access` and requires that package to already exist on the registry — there is no way to configure it for a name that has never been published. [npm-docs-trusted-publishers] [setup-npm-trusted-publish-tool]
- PyPI has an explicit "pending publisher" feature designed for this exact chicken-and-egg case (registering a trusted publisher for a project that doesn't exist yet, so the first-ever publish can go through OIDC with no manual token step). npm does not have an equivalent feature as of mid-2026. [hn-pypi-designer-comment]
- The standard community workaround is publishing a trivial placeholder version (e.g. `0.0.1`) manually (token-based, human-authenticated) purely to make the package "exist," then configuring the trusted publisher afterward. A packaged tool for this, `setup-npm-trusted-publish`, automates the placeholder-publish step. [setup-npm-trusted-publish-tool]
- Each npm package can have exactly one trusted publisher configured at a time; switching CI providers means editing the existing config, not adding a second one. [remarkablemark-blog]
- Separately, npm has since added an `npm trust` command (since ~2026-02-18) to configure trusted publishing across multiple existing packages in one operation — this helps bulk-onboarding already-published packages, but does not remove the "must exist first" requirement for brand-new names. [hn-pypi-designer-comment]
- npm also offers an optional staged-publish mode (publish to a staging area first, require a maintainer's 2FA approval before the release goes public) as a stronger-security alternative once trusted publishing is set up — orthogonal to the pending-publisher gap, doesn't solve it. [remarkablemark-blog]

## SOURCES

**npm-docs-trusted-publishers**
URL: https://docs.npmjs.com/trusted-publishers/
Accessed: 2026-08-21

**hn-pypi-designer-comment**
URL: https://news.ycombinator.com/item?id=46530448
Accessed: 2026-08-21
Quote: "When Trusted Publishing was designed for PyPI, it was made generic across OIDC IdPs and explicitly included an accommodation for creating new projects via Trusted Publishing, called 'pending' publishers... not all subsequent adopters of the Trusted Publishing technique have adopted [this]."

**setup-npm-trusted-publish-tool**
URL: https://github.com/azu/setup-npm-trusted-publish
Accessed: 2026-08-21
Quote: "publishes a minimal placeholder package so you can configure OIDC trusted publishing on npmjs.com afterwards"

**remarkablemark-blog**
URL: https://remarkablemark.org/blog/2025/12/19/npm-trusted-publishing/
Accessed: 2026-08-21

## SYNTHESIS

Practical consequence for any org onboarding a brand-new `@scope/package-name` to npm with trusted publishing as the steady-state goal: the owner (someone with npm publish rights to the scope) must still do one manual, token-or-login-authenticated `npm publish` per new package name first. Trusted-publisher config, and therefore the "no long-lived token ever" property, only starts applying from the *second* publish onward. This is an unavoidable one-time owner-gated step, not a process gap to design around — plan onboarding docs/runbooks accordingly (i.e., don't write an owner click-list that assumes trusted-publisher setup can happen before any publish exists).
