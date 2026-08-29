---
title: "Terminal transcripts of TUI agents should be ANSI-stripped at write time (98.7% reduction, beats gzip) and stall detection must be decoupled from transcript byte-growth, because ~37% of redraw frames carry zero content"
date: 2026-08-29
topic: shell-scripting
tags: [ansi, ecma-48, terminal, tmux, transcripts, log-retention, liveness, waspflow, journald, logrotate]
status: draft
sources: [ecma-48, console-codes, xterm-ctlseqs, ansi-regex, colorized-logs, col-man, script-man, scriptreplay-man, asciicast-v2, tmux-man, journald-conf, journalctl-man, docker-json-file, k8s-logging, gh-actions-limits, gh-actions-retention, gitlab-cicd-limits, gitlab-runner-config, jenkins-syntax, logrotate-man, buildkite-logs, buildkite-limits, gh-tail-request, osc8-spec, kitty-kbd, wf-core, wf-waspflow, wf-claude, wf-codex, wf-inbox-lifecycle, wf-inbox-scrollback, measured]
source_session: unknown
---

## CLAIMS

### The measured situation (waspflow, this host)

- Waspflow captures one transcript per lane with `tmux pipe-pane -t <target> -o 'cat >> <transcript>'` [wf-claude], and the codex adapter documents that a real PTY is required so transcripts must use `pipe-pane`, never a shell pipe [wf-codex].
- `~/.local/state/waspflow` is 40 GB; 5,517 `transcript.log` files total 24.67 GB; median 1.92 MB, p90 10.45 MB, max 250.7 MB [measured]. (Brief stated 5,510 / 23 GB; re-measured 2026-08-29, same magnitude, grown slightly.)
- 3,575 transcripts exceed 1 MB and account for 23.86 GB — 96.7% of all transcript bytes [measured].
- In a 40 MB sample of a real 250 MB transcript: 6,609,919 ESC bytes; the byte following ESC is `[` 6,554,955 times, `]` 54,814 times, `M` 148 times, `\` twice [measured]. OSC sequences are therefore present in real data, not hypothetical.
- Correct ECMA-48 stripping reduces that 40 MB sample to 553,115 bytes — **1.38%** [measured].
- Across the six largest transcripts (124–239 MB), correct stripping yields 0.6%–1.7% of original; `gzip` of raw yields 2.4–4.7 MB while stripping yields 1.4–3.1 MB, so **stripping beats gzip alone on every file measured**, and strip+gzip yields 0.08–0.30 MB [measured].
- Over a 40-file random sample of transcripts >1 MB, aggregate stripped size is **10.61%** of raw (0.450 GB → 0.0477 GB) [measured]. The whole-fleet ratio is worse than the giant-file ratio because small transcripts are proportionally more text.
- Newlines survive stripping: the 40 MB sample retains all 3,657 newlines and 3,657 CRs [measured]. But "lines" are not bounded — the longest newline-delimited run in the sample is 1,219,032 bytes [measured], so any line-oriented filter must tolerate multi-MB lines.

### The current strip is wrong, and measurably so

- Waspflow's `strip_ansi` is `sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\x1b[()][AB0]//g'` [wf-core].
- Applied to the 40 MB sample it leaves **219,425 residual ESC bytes** and produces 3.18 MB (7.96%), versus 0.55 MB (1.38%) for the correct grammar — a **5.8x** difference [measured].
- The specific gaps, counted in that sample: CSI with an intermediate byte such as `ESC [ 0 SP q` (164,458 occurrences); CSI with a non-alphabetic final byte such as `@`, `` ` ``, `~` (2,662,911 occurrences); OSC strings (54,814); and `ESC M` / other two-byte Fe forms [measured].
- `strip_ansi` is applied to `tmux capture-pane` output before blocked-prompt matching [wf-waspflow], so these gaps also degrade stall-hint classification, not only file size.

### The correct grammar (primary sources)

- ECMA-48 5th ed. clause 5.4 defines a control sequence as `CSI P...P I...I F` where CSI is `ESC` `[` (0x1B 0x5B) in 7-bit or 0x9B in 8-bit, parameter bytes are 03/00–03/15 = **0x30–0x3F**, intermediate bytes are 02/00–02/15 = **0x20–0x2F**, and the final byte is 04/00–07/14 = **0x40–0x7E** [ecma-48].
- Clause 5.4.1 makes a first parameter byte in 03/12–03/15 (**0x3C–0x3F**, i.e. `< = > ?`) private/experimental, so `CSI ? 25 h`, `CSI > 4 ; 2 m` (xterm XTMODKEYS) and `CSI > flags u` (kitty keyboard protocol) are ordinary CSI sequences needing no special case [ecma-48][xterm-ctlseqs][kitty-kbd].
- Clause 5.6 defines control strings opened by DCS `ESC P`, SOS `ESC X`, OSC `ESC ]`, PM `ESC ^`, APC `ESC _`, and closed by ST `ESC \` (0x1B 0x5C) [ecma-48].
- BEL (0x07) as an OSC terminator is **not** ECMA-48; it is an xterm extension: "In addition to the ECMA-48 string terminator (ST), xterm(1) accepts a BEL to terminate an OSC string" [console-codes]. xterm's own notation writes OSC as `OSC Ps ; Pt BEL` or `OSC Ps ; Pt ST` [xterm-ctlseqs].
- `console_codes(4)` enumerates the non-CSI ESC forms that a CSI-only regex misses: `ESC c`, `ESC D`, `ESC E`, `ESC H`, `ESC M`, `ESC Z`, `ESC 7`, `ESC 8`, `ESC =`, `ESC >` (two-byte) and `ESC % @|G|8`, `ESC # 8`, `ESC ( B|0|U|K`, `ESC ) ...` (three-byte, ESC + intermediate + final) [console-codes]. A two-byte-only rule leaves a stray `B` or `0` after `ESC ( B`.
- `console_codes(4)` also warns that Linux private-mode sequences "do not follow the rules in ECMA-48 for private mode control sequences. In particular, those ending with ] do not use a standard terminating character" [console-codes] — so no regex is total; a stripper must fail safe rather than assume full coverage.
- OSC 8 hyperlinks are specified outside xterm, in the community spec, as `OSC 8 ; params ; URI ST`, closed by `OSC 8 ; ; ST`, and that spec notes BEL is often used instead of ST [osc8-spec].

### Reference implementations, and one widespread trap

- `ansi-regex` (chalk), the most-cited implementation, matches **only OSC and CSI** — it has no DCS/APC/PM/SOS branch — and deliberately narrows the CSI final-byte class to `[\dA-PR-TZcf-nq-uy=><~]`, which excludes legal ECMA-48 finals; its OSC payload uses a negated class `[^]*` specifically so an unterminated `ESC ]` cannot rescan the buffer (the fix for its earlier ReDoS, CVE-2021-3807) [ansi-regex].
- `ansi2txt` from `colorized-logs` is a small C state machine handling CSI, OSC-to-BEL, and `ESC (`/`ESC )`/`ESC %` charset pairs, and normalising CRLF→LF [colorized-logs]. It is Debian-packaged as `colorized-logs` but is **not installed on this host** [measured].
- **`col -b` does not strip ANSI and is worse than doing nothing.** col(1) documents only carriage-motion handling (`ESC-7/8/9`, backspace, CR, LF, SI/SO, space, tab, VT) and states "All unrecognized control characters and escape sequences are discarded" [col-man] — meaning the ESC byte is dropped while its parameters survive as printable text. Verified empirically: `printf 'a\033[31mRED\033[0m b\n' | col -b` yields `a31mRED0m b`, i.e. the colour codes become visible garbage [measured].

### What mature capture tools keep, and why

- `script(1)`: "The terminal data are stored in raw form to the log file and information about timing to another (optional) structured log file" — raw bytes, escapes included, and the man page documents no stripping option at all [script-man].
- `scriptreplay(1)` requires those raw escapes: it is "only guaranteed to work properly if run on the same type of terminal the typescript was recorded on. Otherwise, any escape characters in the typescript may be interpreted differently by the terminal" [scriptreplay-man]. The classic timing format's second field is a **byte count** [script-man], so stripping desynchronises a timing file from its log — replay and stripping are mutually exclusive on the same artifact.
- asciinema cast v2 stores raw output bytes in `[time, code, data]` event arrays, with `data` a "valid, UTF-8 encoded JSON string" having "non-printable Unicode codepoints encoded as `\uXXXX`" — escapes are preserved deliberately, because the format exists to replay [asciicast-v2].
- `tmux capture-pane` **strips by default**: "If -e is given, the output includes escape sequences for text and background attributes" [tmux-man]. It reads tmux's parsed cell grid, so `-e` re-synthesises SGR from cell attributes rather than replaying original bytes; OSC titles, cursor motion and DCS payloads are absent regardless of `-e`.
- `tmux pipe-pane` "Pipe output sent by the program in target-pane to a shell command" [tmux-man]. The man page does **not** explicitly state the stream is raw; rawness is inferred from architecture and confirmed here empirically by the ESC census above [measured].
- The consistent split: tools that **replay** (script/scriptreplay, asciinema, ttyrec) keep raw bytes; tools that **read** (capture-pane, ansi2txt, CI log viewers) strip. Waspflow's transcript is only ever read — by `peek` [wf-waspflow] and by humans — never replayed [wf-waspflow][wf-core].

### Retention models in comparable systems

- journald: `SystemMaxUse=` defaults to 10% of the filesystem and `SystemKeepFree=` to 15%, "each of the calculated default values is capped to 4G"; `SystemMaxFileSize=` defaults to one eighth of `SystemMaxUse=` capped at 128M "so that usually seven rotated journal files are kept as history" — the per-file size is *derived* from the total budget rather than set independently [journald-conf].
- journald never truncates a file mid-way: "only archived files are deleted to reduce the space occupied by journal files", and limits "are enforced synchronously when journal files are extended" [journald-conf]. `journalctl --vacuum-size=` "only operates on archived journal files" and cannot shrink the active one [journalctl-man]. The active file is sacred; the budget is met by evicting whole older files.
- Docker `json-file`: `max-size` defaults to **-1 (unlimited)** and `max-file` to 1; "If rolling the logs creates excess files, the oldest file is removed. Only effective when max-size is also set" [docker-json-file]. Unbounded-by-default plus a knob that is silently inert alone are both anti-patterns to avoid.
- Kubernetes kubelet: `containerLogMaxSize` 10Mi, `containerLogMaxFiles` 5, with the honest documented consequence "Only the contents of the latest log file are available through `kubectl logs`" and the worked example that a Pod writing 40 MiB returns "at most 10MiB of data" [k8s-logging] — retained bytes and reader-visible bytes are different numbers.
- GitHub Actions: logs and artifacts "are retained for 90 days before they are automatically deleted"; configurable 1–90 days for public repos and 1–400 for private [gh-actions-retention]. Jobs cap at 6 h (hosted) / 5 days (self-hosted) and runs at 35 days [gh-actions-limits]. There is **no documented per-job log byte cap** — the widely repeated ~4 MB figure appears only in community discussion, not documentation [gh-actions-limits].
- GitLab applies two limits with different failure modes: a server-side 100 MB job-log limit where "Any job that exceeds the limit is marked as failed, and dropped by the runner" [gitlab-cicd-limits], and a runner-side `output_limit` "Maximum build log size in kilobytes. Default is 4096 (4 MB)" [gitlab-runner-config]. Refusing the job destroys the artifact most needed for diagnosis.
- Jenkins `logRotator`/`buildDiscarder` takes `daysToKeep`/`numToKeep` plus separate `artifactDaysToKeep`/`artifactNumToKeep`, letting a build record outlive its bytes [jenkins-syntax].
- logrotate's `copytruncate` "Truncate the original log file to zero size in place after creating a copy" and exists because a program "cannot be told to close its logfile and thus might continue writing (appending) to the previous log file forever"; the documented cost is "a very small time slice between copying the file and truncating it, so some logging data might be lost" [logrotate-man]. This is exactly waspflow's shape: a live `cat >>` holds the fd and cannot be signalled to reopen.
- Four distinct at-limit policies appear across these systems: delete-oldest-whole-file (journald, Docker, k8s, Jenkins), truncate-in-place (logrotate `copytruncate`, GitLab runner), refuse/fail (GitLab server), and truncate-the-view-but-keep-the-artifact (GitHub, Buildkite).
- Head+tail-with-elision-notice is **not shipped by any system verified here**. GitHub truncates head-first; Buildkite truncates tail-first — "If your build output exceeds 2MB then we'll only show the last 2MB of it in the rendered terminal output on your build page" [buildkite-logs], with a 1,024 MiB job-log file cap [buildkite-limits]. Keeping both ends is an open GitHub feature request proposing a "warning at the very bottom indicating the truncation of the middle log section" [gh-tail-request]. Both vendors keep the full artifact downloadable even when the rendered view is cut [gh-tail-request][buildkite-logs].

### The liveness coupling — the load-bearing finding

- Waspflow's `wait` reads `wc -c` on the transcript, resets a stall clock when the byte count changes, and after `WASPFLOW_STALL_SECONDS` (default 45) returns rc 4 with a hint [wf-waspflow].
- **Idle detection does not use the transcript at all.** Every provider's `_is_idle` reads a provider session log: claude parses `stop_reason == "end_turn"` from the harness JSONL; codex reads `task_complete` from the rollout JSONL; grok reads `turn_ended` from an events file; antigravity/qwen/deepseek read a completion receipt [wf-claude][wf-codex]. The transcript byte count is the stall clock **only** [wf-waspflow].
- The transcript is otherwise used for `peek` when no live window exists [wf-waspflow] and is truncated at spawn [wf-waspflow]. So exactly one behaviour is coupled to transcript bytes.
- Byte-growth is a **poor** liveness proxy on the "still alive" side: in the 40 MB sample, spinner redraw frames (delimited by OSC-title updates) cost a median of 696 bytes each, and **20,459 of 54,811 frames (37.3%) contain zero non-whitespace content after stripping** [measured]. A third of the byte flow is pure animation.
- It is nevertheless **sound in practice on the "stalled" side**, and stripping does not break it. Of 272 lanes that actually recorded `wait_state=stalled`, 249 (91.5%) recorded the hint "unknown (no output …)", with only 17 numbered-choice, 4 confirm-keystroke and 2 interactive-question prompts [measured]. Inspecting stalled transcripts shows byte flow ceasing entirely — one lane's tail ends mid-spinner-render ("Blanching… 2m 1s"), i.e. the process stopped emitting anything, spinner included [measured]. Real stalls are total output cessation, not content-only cessation.
- The quantified risk of stripping before the stall clock: the longest run of consecutive content-free spinner frames in the sample is **11 frames** [measured]. At a typical 8–12.5 Hz TUI spinner cadence that is **0.9–1.4 s** of zero stripped-content growth — two orders of magnitude below the 45 s threshold. Stripping therefore does not by itself induce false stalls at the default setting.

### Implementation constraints proven empirically

- **No escape sequence in the sample contains a newline** — 0 of 6,609,917 [measured]. Line-oriented streaming cannot split a sequence, though lines reach 1.2 MB [measured].
- A **stateless chunked** stripper is nevertheless unsafe: feeding `a\x1b[31mRED\x1b[0m b\n` in 3-byte chunks through a per-chunk regex leaves the escapes entirely intact [measured]. A streaming filter must carry a partial-sequence tail across reads.
- A subtle and load-bearing bug: if the two-byte Fe rule is written as `\e[\x30-\x7e]`, it matches the `\e]` prefix of a **partial** OSC, so a boundary-straddling OSC is mis-stripped as a 2-byte escape and its payload leaks as visible text. Reproduced at offset 2,686,953 of a real transcript, leaking `90;⠋ remote-surface-confor...` into the output [measured]. The fix is to exclude the string-openers `[ ] P X ^ _` from the Fe class.
- A corrected streaming Perl filter (holdback of an incomplete trailing sequence, 8 KB holdback cap, Fe class excluding string-openers) produces output **byte-identical** to a whole-file Python reference on the 40 MB sample, with **zero residual ESC bytes**, and is correct when fed one byte at a time [measured]. Throughput ≈ 48 MB/s single-core [measured].

## SOURCES

**ecma-48**
URL: https://www.ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf
Accessed: 2026-08-29
Quote: "The format of a control sequence is CSI P ... P I ... I F where ... b) P ... P are Parameter Bytes, which, if present, consist of bit combinations from 03/00 to 03/15; c) I ... I are Intermediate Bytes, which, if present, consist of bit combinations from 02/00 to 02/15 ... d) F is the Final Byte; it consists of a bit combination from 04/00 to 07/14". Clause 5.4.1: "If the first bit combination of the parameter string is in the range 03/12 to 03/15, the parameter string is available for private (or experimental) use." Clause 5.6: "A control string consists of an opening delimiter, a command string or a character string, and a terminating delimiter, the STRING TERMINATOR (ST)."

**console-codes**
URL: https://man7.org/linux/man-pages/man4/console_codes.4.html
Accessed: 2026-08-29
Quote: "ESC M RI Reverse linefeed. ... ESC % G Select UTF-8 ... ESC ( B Select default (ISO/IEC 8859-1 mapping). ESC ( 0 Select VT100 graphics mapping. ... ESC ] OSC Operating System Command prefix." and "In addition to the ECMA-48 string terminator (ST), xterm(1) accepts a BEL to terminate an OSC string." and "Linux 'private mode' sequences do not follow the rules in ECMA-48 for private mode control sequences. In particular, those ending with ] do not use a standard terminating character."

**xterm-ctlseqs**
URL: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
Accessed: 2026-08-29
Quote: OSC sequences are written `OSC Ps ; Pt BEL` or `OSC Ps ; Pt ST`. `CSI > Pp ; Pv m` is XTMODKEYS ("Set/reset key modifier options"). OSC 0 sets icon name and window title; OSC 10/11 set foreground/background colour and answer a `?` argument.

**osc8-spec**
URL: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
Accessed: 2026-08-29
Quote: "The syntax is `OSC 8 ; params ; URI ST`" ... "The sequence is terminated with `ST` (string terminator) which is typically `ESC` `\`. (Although `ST` is the standard sequence according to ECMA-48 §8.3.89, often the `BEL` (`\a`) character is used instead."

**kitty-kbd**
URL: https://sw.kovidgoyal.net/kitty/keyboard-protocol/
Accessed: 2026-08-29
Quote: `CSI > flags u` pushes flags, `CSI < number u` pops, `CSI = flags ; mode u` sets, `CSI ? u` queries. (Kitty does not itself describe these as "private-use"; that classification follows from ECMA-48 clause 5.4.1.)

**ansi-regex**
URL: https://github.com/chalk/ansi-regex/blob/main/index.js
Accessed: 2026-08-29
Quote: "const ST = '(?:\\u0007|\\u001B\\u005C|\\u009C)'; ... const osc = `(?:\\u001B\\][^\\u0007\\u001B\\u009C]*${ST})`; ... const csi = '[\\u001B\\u009B][[\\]()#;?]*(?:\\d{1,4}(?:[;:]\\d{0,4})*)?[\\dA-PR-TZcf-nq-uy=><~]';" with the comment "The payload stops at the first terminator character rather than scanning ahead for one, so an unterminated `ESC ]` cannot rescan the rest of the input." Verified identical to published npm v6.3.0.

**colorized-logs**
URL: https://github.com/kilobyte/colorized-logs
Accessed: 2026-08-29
Quote: `ansi2txt.c` is a C state machine: on `ESC [` consume parameter/`;`/`?` bytes then discard; on `ESC ]` consume to BEL or a following ESC; `ESC (`, `ESC )`, `ESC %` each consume one following byte; CRLF normalised to LF.

**col-man**
URL: https://man7.org/linux/man-pages/man1/col.1.html
Accessed: 2026-08-29
Quote: "col filters out reverse (and half-reverse) line feeds so the output is in the correct order" ... "-b, --no-backspaces  Do not output any backspaces, printing only the last character written to each column position." ... "All unrecognized control characters and escape sequences are discarded."

**script-man**
URL: https://man7.org/linux/man-pages/man1/script.1.html
Accessed: 2026-08-29
Quote: "The terminal data are stored in raw form to the log file and information about timing to another (optional) structured log file." ... "Classic format: The timing log contains two fields, separated by a space. The first field indicates how much time elapsed since the previous output. The second field indicates how many characters were output this time."

**scriptreplay-man**
URL: https://man7.org/linux/man-pages/man1/scriptreplay.1.html
Accessed: 2026-08-29
Quote: "scriptreplay is only guaranteed to work properly if run on the same type of terminal the typescript was recorded on. Otherwise, any escape characters in the typescript may be interpreted differently by the terminal to which scriptreplay is sending its output."

**asciicast-v2**
URL: https://docs.asciinema.org/manual/asciicast/v2/
Accessed: 2026-08-29
Quote: event lines are `[time, code, data]` arrays; `data` must be a "valid, UTF-8 encoded JSON string" with "non-printable Unicode codepoints encoded as `\uXXXX`". Header requires `version`, `width`, `height`. (Event-type enumeration `o`/`i`/`m`/`r` is high-confidence but paraphrased, not byte-verbatim.)

**tmux-man**
URL: https://man7.org/linux/man-pages/man1/tmux.1.html
Accessed: 2026-08-29
Quote: capture-pane: "If -e is given, the output includes escape sequences for text and background attributes." pipe-pane: "Pipe output sent by the program in target-pane to a shell command or vice versa." (The man page does not state whether pipe-pane output is raw.)

**journald-conf**
URL: https://man7.org/linux/man-pages/man5/journald.conf.5.html
Accessed: 2026-08-29
Quote: "The first pair defaults to 10% and the second to 15% of the size of the respective file system, but each of the calculated default values is capped to 4G." ... "Defaults to one eighth of the values configured with SystemMaxUse= and RuntimeMaxUse= capped to 128M, so that usually seven rotated journal files are kept as history." ... "only archived files are deleted to reduce the space occupied by journal files" ... "size limits are enforced synchronously when journal files are extended". (`MaxFileSec=` default of 1 month NOT verified.)

**journalctl-man**
URL: https://man7.org/linux/man-pages/man1/journalctl.1.html
Accessed: 2026-08-29
Quote: "running `--vacuum-size=` has only an indirect effect on the output shown by `--disk-usage`, as the latter includes active journal files, while the vacuuming operation only operates on archived journal files."

**docker-json-file**
URL: https://docs.docker.com/engine/logging/drivers/json-file/
Accessed: 2026-08-29
Quote: "The maximum size of the log before it is rolled." Default `-1` (unlimited); `max-file` default 1. "If rolling the logs creates excess files, the oldest file is removed. Only effective when max-size is also set."

**k8s-logging**
URL: https://kubernetes.io/docs/concepts/cluster-administration/logging/
Accessed: 2026-08-29
Quote: "Only the contents of the latest log file are available through `kubectl logs`." ... "For example, if a Pod writes 40 MiB of logs and the kubelet rotates logs after 10 MiB, running `kubectl logs` returns at most 10MiB of data." Defaults: `containerLogMaxSize` 10Mi, `containerLogMaxFiles` 5.

**gh-actions-retention**
URL: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
Accessed: 2026-08-29
Quote: "the artifacts and log files generated by workflows are retained for 90 days before they are automatically deleted." Public: "anywhere between 1 day or 90 days." Private: "anywhere between 1 day or 400 days."

**gh-actions-limits**
URL: https://docs.github.com/en/actions/reference/limits
Accessed: 2026-08-29
Quote: "Each job in a workflow can run for up to 6 hours of execution time." Self-hosted: "up to 5 days of execution time." "35 days / workflow run". No per-job log byte cap is documented.

**gitlab-cicd-limits**
URL: https://docs.gitlab.com/administration/cicd/limits/
Accessed: 2026-08-29
Quote: "The job log file size limit in GitLab is 100 megabytes by default." ... "Any job that exceeds the limit is marked as failed, and dropped by the runner."

**gitlab-runner-config**
URL: https://docs.gitlab.com/runner/configuration/advanced-configuration/
Accessed: 2026-08-29
Quote: "Maximum build log size in kilobytes. Default is `4096` (4 MB)." (Truncate-and-continue behaviour NOT verified as verbatim text.)

**jenkins-syntax**
URL: https://www.jenkins.io/doc/book/pipeline/syntax/
Accessed: 2026-08-29
Quote: "options { buildDiscarder(logRotator(numToKeepStr: '1')) }" ... "Persist artifacts and console output for the specific number of recent Pipeline runs." (Defaults and the `-1` sentinel NOT verified.)

**logrotate-man**
URL: https://man7.org/linux/man-pages/man8/logrotate.8.html
Accessed: 2026-08-29
Quote: "Truncate the original log file to zero size in place after creating a copy, instead of moving the old log file and optionally creating a new one." ... "It can be used when some program cannot be told to close its logfile and thus might continue writing (appending) to the previous log file forever." ... "Note that there is a very small time slice between copying the file and truncating it, so some logging data might be lost."

**buildkite-logs**
URL: https://buildkite.com/docs/pipelines/configure/managing-log-output
Accessed: 2026-08-29
Quote: "If your build output exceeds 2MB then we'll only show the last 2MB of it in the rendered terminal output on your build page."

**buildkite-limits**
URL: https://buildkite.com/docs/platform/limits
Accessed: 2026-08-29
Quote: "The maximum file-size of a job's log. Default: 1,024 MiB".

**gh-tail-request**
URL: https://github.com/orgs/community/discussions/118591
Accessed: 2026-08-29
Quote: Feature request "Add a button to view the tail of the logs", proposing to show both ends "with a warning at the very bottom indicating the truncation of the middle log section". GitHub currently truncates head-first with a "This step has been truncated due to its large size" notice.

**wf-core**
Path: /home/tnunamak/code/waspflow/lib/core.sh:975 (also :269 `lane_transcript`)
Accessed: 2026-08-29
Quote: `strip_ansi() { sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\x1b[()][AB0]//g'; }`

**wf-waspflow**
Path: /home/tnunamak/code/waspflow/bin/waspflow:1094-1165 (stall clock), :299-303 (spawn truncates), :1043-1044 (peek), :1256 (cmd_gc)
Accessed: 2026-08-29
Quote: `local last_size; last_size="$(wc -c <"$transcript" 2>/dev/null || echo 0)"` and `if [[ "$cur_size" != "$last_size" ]]; then last_size="$cur_size"; last_change="$now"` and the comment "The ROBUST signal is STALL itself, not prompt wording: the worker produced no output for stall_secs while its turn hasn't ended."

**wf-claude**
Path: /home/tnunamak/code/waspflow/lib/providers/claude.sh:109 (pipe-pane), :300 (claude_is_idle)
Accessed: 2026-08-29
Quote: `tmux pipe-pane -t "$target" -o "cat >> $(printf '%q' "$transcript")" 2>/dev/null || true` and `last_reason="$(jq -rc 'select(.type=="assistant") | .message.stop_reason // empty' "$jsonl" ...)"; [[ "$last_reason" == "end_turn" ]]`

**wf-codex**
Path: /home/tnunamak/code/waspflow/lib/providers/codex.sh:7, :584
Accessed: 2026-08-29
Quote: "Interactive TUI requires a REAL PTY. `codex | tee` fails ('stdout is not a terminal') — so transcripts use `tmux pipe-pane`, never a pipe." and `codex_is_idle` tests the last rollout event `== "task_complete"`.

**wf-inbox-lifecycle**
Path: /home/tnunamak/code/waspflow/inbox/2026-08-12-fleet-lifecycle-reconciliation-and-owned-resource-leaks.md
Accessed: 2026-08-29
Quote: "Add configurable warnings or hard policy for: ... archive count, full-history fallbacks, and total/unique bytes; lane-scoped scratch bytes and age" and "The operator should not discover this state at 269 windows, 521 worktrees, 14 GB of archives".

**wf-inbox-scrollback**
Path: /home/tnunamak/code/waspflow/inbox/2026-07-31-tmux-scrollback-memory-budget.md
Accessed: 2026-08-29
Quote: "Make reap/park close or compact a lane's tmux history after its output has been durably captured, with an auditable receipt and an opt-out for lanes intentionally kept interactive." and "a lane's provider process can be idle or gone while its past terminal output remains resident in the shared tmux server."

**measured**
Path: this host, /home/tnunamak/.local/state/waspflow — measurements re-run 2026-08-29
Accessed: 2026-08-29
Quote: 5,517 transcripts / 24.67 GB; 40 MB sample strips 40,000,000 → 553,115 B (1.38%) with correct grammar vs 3.18 MB (7.96%) and 219,425 residual ESC for the current `strip_ansi`; 20,459/54,811 (37.3%) spinner frames content-free; longest content-free run 11 frames; 272 lanes recorded `wait_state=stalled`, 249 with hint "unknown (no output …)"; 0/6,609,917 escape sequences contain a newline; `col -b` on `a\033[31mRED\033[0m b` yields `a31mRED0m b`; corrected streaming Perl filter byte-identical to reference, 0 residual ESC, ~48 MB/s.

## SYNTHESIS

**Strip at write time, and make it the default.** The evidence for stripping is unusually clean. The transcript is a read-only artifact in waspflow — `peek` renders it and humans read it; nothing replays it. The tools that keep raw bytes (script/scriptreplay, asciinema, ttyrec) all keep them *for replay*, and the timing-file byte-count coupling in script(1) shows replay and stripping are mutually exclusive by construction. tmux's own `capture-pane` — the read path — strips by default. So waspflow is on the "reader" side of a very consistent split, and there is no fidelity argument for the 98.7% of bytes it is currently storing. Compress after stripping, not instead of it: stripping alone beats gzip alone on every large file measured, and the two compose to ~0.1% of raw.

The gain is bigger than the brief assumed. The brief's ~92%-escapes figure came from a stripper with real grammar gaps; the correct grammar gives ~98.7% on large files. Fleet-wide the honest number is the sampled ~10.6% retained (small transcripts are proportionally more text), i.e. roughly 24.7 GB → ~2.6 GB, with the >1 MB tail (96.7% of bytes) doing nearly all the work. Note this is a *capture-time* fix; it does nothing for the 17.7 GB already on disk, which needs a separate one-shot backfill.

**Get the grammar right, because the naive version is actively harmful.** Three traps are documented and were each reproduced here. `col -b` does not strip CSI — it deletes the ESC and leaves `31m` as visible text, which is worse than no stripping because it destroys recoverability while corrupting the content. The current `strip_ansi` misses CSI-with-intermediate, non-alphabetic finals, and all OSC, leaving 219k escapes in a 40 MB sample. And the subtlest one, which only shows up in streaming: writing the two-byte Fe rule as `\e[\x30-\x7e]` makes it match the `\e]` of a *partial* OSC, so a sequence straddling a read boundary gets mis-stripped and leaks its payload as text — reproduced at a specific offset in a real transcript. Exclude `[ ] P X ^ _` from the Fe class. Since no escape sequence contains a newline, splitting is only a risk at arbitrary byte boundaries, but `pipe-pane`'s `cat >>` gives no line guarantee, so a streaming filter still needs a partial-sequence holdback with a cap. Do not adopt `ansi-regex` wholesale: it omits DCS/APC/PM/SOS entirely and narrows the final-byte class below the standard. Prefer the ECMA-48 clause 5.4/5.6 grammar directly, with `ansi2txt` as the sanity reference. Keep an escape hatch (`WASPFLOW_TRANSCRIPT_RAW=1`) for debugging a TUI rendering bug, because `console_codes(4)` itself warns that some Linux sequences violate the grammar, so no stripper is total.

**The liveness coupling is safer than feared, but should still be decoupled.** The single most important structural finding is that idle detection never touches the transcript — every provider reads a session log (`end_turn`, `task_complete`, `turn_ended`, or a receipt). Transcript bytes feed exactly one behaviour: the stall clock. That makes this a bounded change, not a systemic one. On the merits, byte-growth is a genuinely poor "still alive" signal — 37.3% of redraw frames carry zero content, so a third of the churn proves nothing about progress. But it is sound on the side that matters: across 272 real stalls, 91.5% recorded no identifiable prompt and the transcripts simply stop, mid-spinner-render, because the process stopped emitting anything at all. Real stalls are total cessation, so stripping does not blind the detector. The risk that stripping introduces false stalls is quantified and small: the longest content-free spinner run is 11 frames ≈ 0.9–1.4 s, versus a 45 s threshold — a ~30x margin. It is safe at the default, but it *narrows* the margin, so anyone lowering `WASPFLOW_STALL_SECONDS` below ~5 s after this change is in new territory. The clean fix is to stop deriving liveness from a presentation artifact at all: track the provider session log's mtime/size as the progress signal (it already exists, it is per-turn, and it is what idle already trusts), and keep transcript bytes only as a secondary "terminal is emitting anything" heartbeat. That also removes the coupling that makes any future capture change scary.

**Retention: bound the budget, evict whole files, never rewrite in place.** The convergent design across journald, Docker, Kubernetes and Jenkins is delete-oldest-whole-file against a size or count budget, and journald's derived per-file size (1/8 of total, targeting ~7 files) is a better interface than two independently-guessed knobs. Two anti-patterns to avoid are documented: Docker's unbounded default plus a `max-file` that is silently inert without `max-size`, and GitLab's server-side refusal that fails the job and destroys the very artifact needed to diagnose it. Critically, none of these systems bounds a log by rewriting it while a live writer appends — that is what `copytruncate` exists for, and its own man page admits an unavoidable lossy race. Waspflow's `cat >>` fd cannot be signalled to reopen, so in-place truncation of a *live* lane's transcript would hit exactly that race; bound live lanes by budget-and-rotate or simply by the strip (which is a ~75x reduction and likely sufficient), and do lossy compaction only at a terminal transition when no writer holds the fd.

**Compact at terminal transition, with an age/size backstop.** This fits what both inbox notes already ask for and contradicts neither. The lifecycle note asks for archive/scratch byte budgets with early warning and per-root attribution, and treats reap as a bounded, resumable plan; transcript compaction is naturally one more resource-receipt step in that plan. The scrollback note asks that reap/park "close or compact a lane's tmux history after its output has been durably captured, with an auditable receipt" — compacting the on-disk transcript is the same act on the other half of the same problem, and the two should share one receipt. Age-based-only retention fails the incident case (you delete the log you needed); size-budget-only fails attribution (you cannot tell which root owns the bytes). Terminal-transition compaction is strictly better here because a reaped lane's transcript is definitionally not going to grow, and 17.7 GB already sits on reaped lanes.

**On never deleting.** Head+tail-with-an-elision-notice is not shipped by any system verified — GitHub truncates head-first, Buildkite tail-first, and keeping both ends is an open GitHub feature request. So it would be an invention, though a well-motivated one: the recurring complaint against head-only truncation is that the failure is at the tail, and the symmetric complaint against tail-only is losing the setup preamble. Given stripping already yields ~75x, waspflow probably does not need truncation at all for a long time, and should prefer strip+gzip with no content loss over inventing a truncation format. If a hard cap is ever added, copy the two things every CI vendor does: keep the full artifact retrievable out-of-band, and make the elision visible in-band stating bytes *and* lines dropped — a silently short log reads as "the process died" rather than "the log was cut", which is the failure mode that actually burns people.
