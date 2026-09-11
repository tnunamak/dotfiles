---
title: "Open-source and standards projects give a mailing list a plain text link, never its own icon, in a footer row of branded channel icons"
date: 2026-09-11
topic: frontend-design
tags: [footer, icons, community-channels, open-source, lfdt, simple-icons, mailing-list]
status: verified
sources: [kubernetes, prometheus, rust, apache, lfdt, simple-icons]
source_session: 0c6d5e0c-24d1-46c7-a731-02f2eeb59496
---

## CLAIMS

- No project checked renders a mailing list with its own icon inside an icon-bearing
  channel row. [kubernetes] [prometheus] [rust] [apache] [lfdt]
- Icon rows are reserved for platforms carrying a real brand mark — Slack, Discord,
  GitHub, and social networks. [apache] [lfdt] [rust]
- Two placements are both attested for the mailing list: a plain text link inside the
  same list as other channels [prometheus] [rust], or a plain text link moved to an
  adjacent non-icon section [apache] [lfdt].
- LF Decentralized Trust's own site uses the pattern: its footer icon row is
  LinkedIn/YouTube/X only, with "Mailing lists" as a plain text link elsewhere. [lfdt]
- Kubernetes omits mailing lists entirely from its icon-bearing community grid, where
  Slack, GitHub, Forum and ServerFault all carry icons. [kubernetes]
- simple-icons 13.21.0 contains 3296 icons and has no generic envelope/mail mark, no
  Google Groups mark, and no groups.io mark. It carries only branded email-service
  logos (Gmail, ProtonMail, Mailgun), none of which denote a generic mailing list.
  [simple-icons]

## SOURCES

**kubernetes**
URL: https://kubernetes.io/community/
Accessed: 2026-09-11

**prometheus**
URL: https://prometheus.io/community/
Accessed: 2026-09-11
Quote: Mailing lists (Google Groups) appear in a text-only section; only social media and GitHub receive logos, in a separate row.

**rust**
URL: https://www.rust-lang.org/community
Accessed: 2026-09-11
Quote: Community channels are plain hyperlinks; the separate footer social row (Mastodon/Bluesky/YouTube/GitHub) uses SVG icons.

**apache**
URL: https://www.apache.org/
Accessed: 2026-09-11
Quote: "Mailing Lists" sits as a plain text link in the Projects section, outside the icon-bearing Slack/GitHub/LinkedIn/YouTube/X/Bluesky/Mastodon row.

**lfdt**
URL: https://www.lfdecentralizedtrust.org/
Accessed: 2026-09-11
Quote: Footer icon row is LinkedIn/YouTube/X only; "Mailing lists" is a plain text link elsewhere, with no icon.

**simple-icons**
URL: node_modules/.pnpm/simple-icons@13.21.0/node_modules/simple-icons/_data/simple-icons.json
Accessed: 2026-09-11
Quote: 3296 icons; no envelope, Google Groups, or groups.io mark.

## SYNTHESIS

The question arises whenever a footer groups community channels and one of them is a
mailing list: giving it an icon means inventing a glyph, and omitting one leaves a
ragged left edge beside its icon-bearing siblings. The uniform answer in this peer
group is to accept the asymmetry — the ragged edge is the convention, not a defect.

The underlying rule is that an icon in these rows denotes a *brand*, not a *channel*.
A mailing list has no brand mark to use, so a generic envelope would be a different
kind of symbol sitting in a row of logos, which reads as a new visual register rather
than a missing one. That the icon set most of these projects draw from (simple-icons)
deliberately carries no generic envelope is consistent with the same rule.

Caveat: verified for Kubernetes, Prometheus, Rust, Apache and LFDT by fetching the
live pages. IETF and Zephyr were not checked. Hyperledger's pre-migration participate
URL now 404s, so its current state is unconfirmed.
