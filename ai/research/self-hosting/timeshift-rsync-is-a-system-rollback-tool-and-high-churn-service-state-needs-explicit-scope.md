---
title: "Timeshift rsync is a system rollback tool, and high-churn service state needs explicit scope"
date: 2026-07-24
topic: self-hosting
tags: [timeshift, rsync, snapshots, docker, retention]
status: settled
sources: [timeshift-readme, mint-install-guide]
source_session: 019f0e5e-7353-7133-80ec-0728898f04d7
---

## CLAIMS

- Timeshift is designed to protect system files and settings rather than user data; user home directories are excluded by default. [timeshift-readme]
- In rsync mode, Timeshift shares unchanged files between snapshots with hard links, while each snapshot remains browseable as a full system tree. [timeshift-readme]
- The Timeshift maintainers recommend placing snapshots on an external, non-system partition for best results. [timeshift-readme]
- Timeshift supports retention by hourly, daily, weekly, monthly, and boot levels; its documented response to capacity pressure is to reduce enabled levels and retained snapshot counts. [timeshift-readme]
- Linux Mint's installation guide describes rsync snapshots as incremental: the first snapshot is large and later ones consume additional space only for changed files. [mint-install-guide]

## SOURCES

**timeshift-readme**
URL: https://github.com/linuxmint/timeshift
Accessed: 2026-07-24
Quote: "Timeshift is designed to protect only system files and settings."

**mint-install-guide**
URL: https://linuxmint-installation-guide.readthedocs.io/en/latest/timeshift.html
Accessed: 2026-07-24
Quote: "System snapshots are incremental so although the first snapshot takes a significant amount of spaces, new snapshots only take additional space for files which have changed."

## SYNTHESIS

On a workstation that already has separate application/data backups, Timeshift should be treated as a bounded OS rollback layer. Keep it off the system disk when practical. On the same disk, its scope should exclude independently backed-up high-churn service state such as Docker/container runtimes and databases after a restore test establishes the desired recovery boundary. Measure the entire snapshot tree with one `du` traversal because summing individual snapshots double-counts hard-linked files.
