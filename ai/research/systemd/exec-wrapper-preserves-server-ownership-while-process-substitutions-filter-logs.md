---
title: "A Bash exec wrapper can preserve direct service ownership while process substitutions keep line-filtered logs"
date: 2026-07-13
topic: systemd
tags: [systemd, bash, exec, journald, logging]
status: draft
sources: [bash-exec, bash-process-substitution, journald-streams]
---

## CLAIMS

- Bash `exec command` replaces the shell without creating a new process. [bash-exec]
- Bash `>(list)` process substitution runs `list` asynchronously and routes writes to the substitution's filename into that list. [bash-process-substitution]
- When a systemd unit's standard streams are connected to journald, newline-delimited output becomes separate journal records. [journald-streams]

## SOURCES

**bash-exec**
URL: https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html
Accessed: 2026-07-13
Quote: "If command is supplied, it replaces the shell without creating a new process."

**bash-process-substitution**
URL: https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html
Accessed: 2026-07-13
Quote: "The process list is run asynchronously" and writing to `>(list)` provides input for `list`.

**journald-streams**
URL: https://www.freedesktop.org/software/systemd/man/252/journald.conf.html
Accessed: 2026-07-13
Quote: "the data read is split into individual log records at newline" when unit streams are connected to the journal.

## SYNTHESIS

For a user service whose launcher must remove only known noisy lines, assemble the payload command in a Bash array and invoke it with `exec`, leaving stdout and stderr redirected through line-buffered process substitutions. This avoids a wrapper process becoming the service's long-lived main process while retaining the existing stream-filtering behavior. The command array should also be printable with `%q` for a deterministic, shell-replayable inspection mode.
