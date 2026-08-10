---
title: "Hand-generating secrets in the headline self-host quickstart is split roughly evenly across respected OSS projects, so it is a defensible-but-dated convention rather than an outlier"
date: 2026-08-04
topic: self-hosting
tags: [self-hosting, onboarding, secrets, docker, quickstart, prior-art]
status: draft
sources: [opencode, supabase-docker, plausible-ce, ghost-docker, umami-install]
source_session: c8ba7cb1-e76a-4313-810d-cf923cd88989
---

## CLAIMS

- opencode's headline install is a single line, `curl -fsSL https://opencode.ai/install | bash`, with zero secrets and zero sentences of prose between the subheadline and the command; the feature list below it is a plain `<ul>` of a 1-3 word bold label plus a ~9-15 word description, not a card grid. [opencode]
- Supabase's currently-recommended Docker self-host path is one line, `curl -fsSL https://supabase.link/setup.sh | sh`, and the script generates all secrets and asymmetric JWT keys itself; the user never runs `openssl rand`. Its legacy manual path ships placeholder secrets in `.env.example` with an explicit "you should never start your self-hosted Supabase using these defaults" warning and points at `utils/generate-keys.sh`. [supabase-docker]
- Plausible Community Edition's real quickstart still has the user pipe `openssl rand -base64 48` into `.env` by hand: `echo "SECRET_KEY_BASE=$(openssl rand -base64 48)" >> .env`. [plausible-ce]
- Ghost's Docker install requires the user to generate two secrets by hand, `DATABASE_ROOT_PASSWORD` and `DATABASE_PASSWORD`, each via `openssl rand -hex 32`, as plain numbered steps inside the primary quickstart with no security-callout framing. [ghost-docker]
- Umami's Docker path is `docker compose up -d` with no secret generation; it ships static default credentials (`admin`/`umami`) and warns the user to change the password immediately after first login. [umami-install]
- Tally across six checked paths: three fully automate secret generation in the headline quickstart (opencode, Supabase current, Umami) and two require hand-run `openssl rand` (Ghost, Plausible CE), with Supabase's legacy path a placeholder-plus-generator-script hybrid. [opencode][supabase-docker][umami-install][ghost-docker][plausible-ce]

## SOURCES

**opencode**
URL: https://opencode.ai
Accessed: 2026-08-04
Quote: "The open source AI coding agent" / "curl -fsSL https://opencode.ai/install | bash"

**supabase-docker**
URL: https://supabase.com/docs/guides/self-hosting/docker
Accessed: 2026-08-04
Quote: "Generate all secrets, including a random `DASHBOARD_PASSWORD`, and the asymmetric JWT signing key pair (runs `generate-keys.sh` and `add-new-auth-keys.sh`...)"

**plausible-ce**
URL: https://github.com/plausible/community-edition
Accessed: 2026-08-04
Quote: "echo \"SECRET_KEY_BASE=$(openssl rand -base64 48)\" >> .env"

**ghost-docker**
URL: https://docs.ghost.org/install/docker/
Accessed: 2026-08-04
Quote: "3. `DATABASE_ROOT_PASSWORD` : generate a random password with `openssl rand -hex 32`"

**umami-install**
URL: https://umami.is/docs/install
Accessed: 2026-08-04
Quote: "The default login credentials are username `admin` and password `umami`. Important: Change the default password immediately after your first login."

## SYNTHESIS

This refines, and in one place corrects, the May 2026 entry
`self-hostable-app-onboarding-expectations-secret-generation-tunnels-first-boot-wizards.md`.
That entry recorded Supabase as shipping a `generate-secrets.sh` the operator invokes;
as of August 2026 Supabase's *recommended* path is a single piped `setup.sh` that runs
generation itself, so the trend line is moving toward full automation.

The practical consequence: do not argue "everyone automates secrets, our six-line
quickstart is embarrassing" — Ghost and Plausible, both well-regarded, still make the
user do it, and that argument collapses under one counter-example. The honest framing
is that hand-generation is a defensible *older* convention, and full automation is what
the projects most often cited as best-in-class quickstart UX now do.

The decision rule that follows: if a project's runtime can already self-generate and
persist secrets on first boot, shipping a multi-line `openssl` preamble is a packaging
choice being paid for in onboarding friction, not a security requirement. Check whether
the capability already exists on some image/target before treating the long quickstart
as inherent — in the PDPP case that this session investigated, a one-command image with
first-boot generation already existed and simply was not the one being advertised.

Secondary, reusable observation for product-page work: opencode's feature list is a
plain bulleted list of bold-label + one-line, not cards. Cards give N one-line facts the
visual weight of N sections, which is the wrong trade when the page's job is to get
someone to run one command.
