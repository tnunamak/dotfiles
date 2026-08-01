---
title: "Docker Sandboxes install preflight must validate the real microVM runtime, not just the CLI"
date: 2026-07-21
topic: docker-sandboxes
tags: [docker-sandboxes, sbx, installation, kvm, policy, diagnostics]
status: settled
sources: [docker-get-started, docker-local-policy, docker-troubleshooting]
source_session: 2ed248d2-fcb3-4840-b3af-f4316aeef2de
---

## CLAIMS

- Docker's Ubuntu setup uses Docker's apt repository, `docker-sbx`, KVM availability, membership in the `kvm` group, and `sbx login`; it states that sandboxes will not start when KVM is unavailable. [docker-get-started]
- Docker documents `sbx diagnose` as the common-issue diagnostic surface and says it checks CLI, daemon reachability, version mismatch, storage, and authentication. [docker-troubleshooting]
- Docker documents `sbx policy init balanced` as the non-interactive way to initialize a global policy before other sbx commands. [docker-local-policy]

## SOURCES

**docker-get-started**
URL: https://docs.docker.com/ai/sandboxes/get-started/
Accessed: 2026-07-21

**docker-local-policy**
URL: https://docs.docker.com/ai/sandboxes/governance/local/
Accessed: 2026-07-21

**docker-troubleshooting**
URL: https://docs.docker.com/ai/sandboxes/troubleshooting/
Accessed: 2026-07-21

## SYNTHESIS

A version-only detector cannot establish that an sbx-backed application is runnable. The safe readiness boundary is the same sbx profile that will launch work, with explicit checks for package-backed runtime compatibility, daemon health, initialized policy, effective KVM access, and Docker authentication. `sbx policy init balanced` is safe only as an explicit user-selected repair; privileged package, group, and login actions should remain copy-paste instructions.
