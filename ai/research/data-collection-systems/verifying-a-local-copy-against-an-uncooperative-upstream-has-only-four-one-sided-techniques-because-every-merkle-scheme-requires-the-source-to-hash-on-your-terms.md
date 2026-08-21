---
title: "Verifying a local copy against an upstream you don't control has only four one-sided techniques (internal consistency, watermark regression, sequence gaps, source-frame sampling) because every Merkle/set-reconciliation scheme structurally requires the source to compute hashes under a partitioning and canonicalization the client chose — and the backup industry's flagship integrity checks (restic check, borg check, zpool scrub) verify a repository against ITSELF and would pass on a copy that silently missed half the source"
date: 2026-08-19
topic: data-collection-systems
tags: [completeness-verification, reconciliation, backup-verification, merkle-trees, audit-sampling, change-feed-vs-snapshot, coverage-proof]
status: draft
sources: [restic-check, restic-backup, borg-check, rclone-check, zfs-scrub, aws-restore-testing, cisa-3-2-1, cassandra-repair, cassandra-source, dynamo-paper, rsync-tech-report, syncthing-bep, imap-rfc9051, imap-rfc7162, carddav-rfc6578, gmail-getprofile, gmail-history, people-synctoken, slack-conversations, hanley-rule-of-three, pcaob-as2315, koenderks-stratified, iso-2859-ansi, datafold-data-diff, dbt-utils, s3-inventory, glacier-inventory, stripe-reports, eppstein-iblt, meyer-range-reconciliation]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Scope note: this entry is about MECHANISMS for proving a copy matches an upstream.
It deliberately does NOT cover how to PRESENT completeness/health status to a user —
that is settled by the 2026-08-16/19 entries on collector health vocabularies and
permanently-partial sync copy. Those answer "what words go on the screen"; this
answers "what can you actually know, and what does it cost".
-->

## CLAIMS

### The backup industry's integrity checks are self-referential

- restic documents two check tiers: default verifies "Structural consistency and integrity, e.g. snapshots, trees and pack files"; `--read-data` adds verification of stored bytes. The default "does not verify that the actual pack files on disk in the repository are unmodified, because doing so requires reading a copy of every pack file in the repository." [restic-check]
- restic scopes `check` explicitly to itself: run it "to make sure **the internal structure of the repository** is free of errors." No source path is an argument to the command. [restic-backup]
- restic documents a case where a backup is empty, the repository is internally perfect, and every check passes: "**Restic cannot detect if data read from stdin is complete or not.**" Its worked example is that "if `mysqldump` fails to connect to the MySQL database, the restic backup will nevertheless succeed in creating an _empty_ backup". The prescribed remedy is explicitly outside the tool — "additional checks (outside of restic)". [restic-backup]
- `borg check` step 1 checks repository objects "by size and hash"; step 2 checks archive metadata and "requires reading archive and file metadata, but not data." `--verify-data` adds full cryptographic verification, "very time-consuming", and Borg states "Running it periodically is therefore recommended." [borg-check]
- Borg's partial-check mode is time-boxed, with a worked cadence: "Assuming a complete check would take 7 hours, then running a daily check with `--max-duration=3600` (1 hour) would result in one full repository check per week." But partial checks "can only perform non-cryptographic checksum checks on the repository files" and force `--repository-only`, excluding archive checks. [borg-check]
- `borg check` takes no source path; a chunk never created because a source file was never read is not a dangling reference, so the "all chunks referencing files (items) in the archive exist" check passes trivially. [borg-check]
- `zpool scrub` "examines all data in the specified pools and verifies each block's checksum"; scope is blocks the pool holds. No explicit sentence stating "a scrub cannot detect data that was never written" was found — the limitation is structural (an unwritten file has no block to checksum), not documented as a disclaimer. A scrub on a live pool can "progress beyond 100% completion" because the pool changes underneath, i.e. scrub has no fixed manifest of what *should* exist. [zfs-scrub]
- `rclone check` is the exception: it "Checks the files in the source and destination match", emitting five distinct categories — `=` identical, `-` missing on source, `+` missing on destination, `*` present both but different, `!` error reading or hashing. `+` is precisely the "the copy missed source items" verdict restic/borg/zfs structurally cannot emit, and `!` keeps errors as their own class rather than folding them into "match". [rclone-check]
- rclone's cheap path requires source cooperation: "To use the verify checksums when transferring between cloud storage systems they must support a common hash type." Absent that, the documented fallbacks are `--size-only` ("only compare the sizes not the hashes") or `--download`, which "will download the data from both remotes and check them against each other on the fly… useful for remotes that don't support hashes". `--one-way` blinds half the space: "extra files in the destination that are not in the source will not be detected." [rclone-check]
- AWS Backup restore testing validates **restorability, not fidelity**: it "provides automated and periodic evaluation of **restore viability**". It is explicitly sampled — "for each selected protected resource, AWS Backup restores at most one recovery point", chosen by a "latest-or-random" algorithm. Content validation is an optional customer-authored bolt-on via EventBridge + Lambda + `PutRestoreValidationResult`; AWS's sample code leaves the check as a stub (`// TODO: Validate the resource`). [aws-restore-testing]
- The 3-2-1 rule has a genuine government primary source (CISA/US-CERT, "Data Backup Options", Ruggiero & Heckathorn, CMU SEI, 2012), which itself footnotes the rule to Peter Krogh, *The DAM Book*, 2nd ed., 2009 — the rule originates in photography asset management, not security standards. The same document names the relevant threat: "Rolling backups can silently propagate any corruption or malware in the primary files to the backup files." [cisa-3-2-1]
- NEGATIVE RESULT: the aphorism "an untested backup is not a backup" was **not** found in any fetched primary source, including the CISA document. It should not be attributed to CISA/US-CERT. [cisa-3-2-1]

### Every Merkle / set-reconciliation technique is two-sided

- Cassandra repair "compares the data with merkle trees, which are a hierarchy of hashes." Tree depth is bounded (`repair_session_max_tree_depth` defaults to 20 in trunk; pre-4.0/CASSANDRA-14096 used a hardcoded 15; in practice capped lower by a memory budget). `MerkleTree`'s javadoc gives the leaf-coverage rule: "100/(2^depth) is the % of the key space covered by each subrange of a fully populated tree." [cassandra-repair] [cassandra-source]
- A Cassandra Merkle leaf covers a token RANGE, not a row, so a one-row divergence forces streaming the leaf's whole range; `MerkleTree.difference` returns "A list of the **largest contiguous ranges** where the given trees disagree", and when no valid midpoint exists it degrades further ("a range that's too small to split - we'll simply report the whole range as inconsistent"). [cassandra-source]
- Building a Cassandra Merkle tree is a full read of the data: validation "Performs a **readonly 'compaction' of all sstables** in order to validate complete rows, but without writing the merge result", hashing "every row present in the CF". Cost is O(dataset) regardless of how little diverged. [cassandra-source]
- Dynamo states the advantage — "each branch of the tree can be checked independently without requiring nodes to download the entire tree or the entire data set" — and the disadvantage verbatim: "The disadvantage with this scheme is that many key ranges change when a node joins or leaves the system thereby requiring the tree(s) to be recalculated." It requires both sides to maintain trees in the same partitioning: "**Each node maintains a separate Merkle tree** for each key range". [dynamo-paper]
- rsync's delta algorithm is two-sided and the DESTINATION does the hashing: "β splits the file B into a series of non-overlapping fixed-sized blocks of size S bytes… For each of these blocks β calculates two checksums… β sends these checksums to α." Against a server that cannot execute the block-checksum scheme, no delta is possible. (zsync's workaround has the *publisher* pre-generate a control file of block checksums — still the source hashing in a client-chosen scheme, just ahead of time.) [rsync-tech-report]
- Syncthing requires both ends to run Syncthing and exchange a mandatory block-hash index: "Each device has one or more folders of files described by the local model, **containing metadata and block hashes. The local model is sent to the other devices in the cluster.**" Block sizes are a fixed negotiated power-of-two ladder. [syncthing-bep]
- IBF / Difference Digest (Eppstein et al., SIGCOMM 2011) is explicitly two-host: the sets "are stored at two distinct hosts and attempt to compute the set difference with minimal communication". No single-sided mode exists. [eppstein-iblt]
- Range-based set reconciliation (Meyer; used by Willow/Earthstar) requires the remote to fingerprint its own data: "When an endpoint receives a fingerprint for a range… **it quickly computes the fingerprint over its local items in the same range**". O(log n) rounds. [meyer-range-reconciliation]
- CRUX (synthesized across the five sources above): the requirement is a three-part conjunction, and consumer APIs fail all three — (1) the source must execute your reconciliation code over its own storage; (2) it must agree on your PARTITIONING scheme (token ranges, block size S, power-of-two ladder), since two trees are comparable only if built identically; (3) it must agree on your CANONICALIZATION and hash function, since a reordered JSON field changes every hash without changing semantics. [cassandra-source] [dynamo-paper] [rsync-tech-report] [syncthing-bep]
- The nearest one-sided thing is HTTP ETag/`If-None-Match` and cursor/`updated_since` change detection — but the SERVER picks the scheme and granularity, so the client learns only "this response changed", never which records differ, and cannot *prove* completeness. [rsync-tech-report]

### What real consumer APIs actually offer (accessed 2026-08-19)

- IMAP is the best case and offers a graduated ladder. UIDs "MUST be strictly ascending in the mailbox at all times", but "Unlike message sequence numbers, unique identifiers are **not necessarily contiguous**" — so a UID hole cannot distinguish "never fetched" from "expunged". [imap-rfc9051]
- IMAP `UIDNEXT` "MUST NOT change unless new messages are added" and "MUST change whenever new messages are added… **even if those new messages are subsequently expunged**" — an append-only arrival watermark, not a size gauge. [imap-rfc9051]
- IMAP `STATUS` returns MESSAGES, UIDNEXT, UIDVALIDITY, UNSEEN, DELETED, SIZE in one round trip with an EXACT count, no extension required. Caveats: it "is not guaranteed to be fast… it can be quite slow" (server may open the mailbox read-only internally), "SHOULD NOT be used on the currently selected mailbox", and "MUST NOT be used as a 'check for new messages in the selected mailbox' operation". [imap-rfc9051]
- The client-side "your cache is invalid" MUST is NOT in base IMAP. RFC 9051/3501 state only the server obligation on UIDVALIDITY. The client MUST lives in RFC 7162 §6 (updating RFC 4549): on UIDVALIDITY change the client "MUST: empty the local cache of that mailbox; 'forget' the cached HIGHESTMODSEQ value…". Cite 7162/4549, not 3501/9051. [imap-rfc7162] [imap-rfc9051]
- QRESYNC's `VANISHED (EARLIER)` is the only surveyed mechanism that reports deletions the client never witnessed, without full re-enumeration. All three degradation paths are safe: UIDVALIDITY mismatch → server ignores parameters; no persistent mod-sequences → `NOMODSEQ`; client modseq older than retained history → server "MUST behave as if it was requested to report all expunged messages", i.e. over-reports rather than silently under-reporting. [imap-rfc7162]
- RFC 9051 does NOT fold in QRESYNC/CONDSTORE; they remain separate optional extensions the EXTRA WG declined to mandate. A client must negotiate and handle absence. [imap-rfc9051]
- RFC 6578 (WebDAV sync, used by CardDAV/Apple Contacts) defines the snapshot-vs-delta distinction NORMATIVELY. Empty token = full inventory: "When the DAV:sync-collection request contains an empty DAV:sync-token element, the server **MUST return all member URLs** of the collection… and it **MUST NOT return any removed member URLs**." Non-empty token returns only changed-or-removed members. Invalid token → `DAV:valid-sync-token` precondition, signalled as 403. Truncation → 207 + 507 with a usable token to page onward. The RFC anticipates the failure directly: the client "has to fall back to synchronizing the entire collection by re-running the report request using an empty token value." [carddav-rfc6578]
- Gmail exposes an exact total (`getProfile.messagesTotal`, no approximation caveat) but `messages.list.resultSizeEstimate` is "**Estimated** total number of results" — two different trust levels from one provider. [gmail-getprofile]
- Gmail `historyId` values "increase chronologically but are **not contiguous** with random gaps", so they do not support client-side gap detection. History is "typically available for at least one week and often longer. However, the time period… may be **significantly less**"; a stale id 404s and forces a full sync. [gmail-history]
- Google People `syncToken` returns "**only the resources changed** since the last request" and expires in 7 days (`EXPIRED_SYNC_TOKEN` / 410 → full sync). Deletions arrive as tombstones (`PersonMetadata.deleted: true`), not omissions. Docs state "**Incremental syncs are not intended for read-after-write use cases**" (propagation delay of minutes). [people-synctoken]
- DANGEROUS SILENCE: Google People defines `totalItems` only as "The total number of items in the list without pagination" and is SILENT on what it means in a syncToken response. A client reading `totalItems` from a delta response as an inventory count has no documentation telling it that is wrong. [people-synctoken]
- Slack's standard Conversations API offers NO total-message count field anywhere, and `ts` is documented as "unique" and "sortable" but never as monotonic or dense — so neither total-count nor gap-detection verification is available. Oldest-item IS cheap (`oldest=0&inclusive=true&limit=1`). The Events API is push-only and cursors "do not persist for hours or days". [slack-conversations]
- ChatGPT consumer conversation history has no documented API at all; bulk export only. [slack-conversations]
- CardDAV/RFC 6352 defines no count property and no sort in `addressbook-query`; ETags only, no sequence — so neither total-count nor gap detection is available. [carddav-rfc6578]
- CROSS-CUTTING: an empty delta NEVER means "nothing exists". Only IMAP distinguishes "unchanged" from "deleted" (`VANISHED`) *and* refuses to guess when it cannot (`NOMODSEQ` → tagged BAD). CardDAV (403) and People (410) signal token invalidity loudly, which is safe; the danger zone is a *valid* token returning few items that a client misreads as an inventory. [carddav-rfc6578] [people-synctoken] [imap-rfc7162]

### The statistics of sampling, and its one fatal misuse

- The rule of three has a genuine primary source (Hanley & Lippman-Hand, JAMA 1983): "if none of n patients shows the event about which we are concerned, we can be 95% confident that the chance of this event is at most three in n (ie, 3/n)." The approximation "agrees with the exact calculation to the nearest percentage point" for n > 30. [hanley-rule-of-three]
- Higher confidence levels use the same derivation with a different constant: "For a 99% confidence interval, the corresponding shortcut is a 'rule of 4.6'… while for 99.9% confidence one uses a 'rule of 6.9'." [hanley-rule-of-three]
- ARITHMETIC INDEPENDENTLY VERIFIED (computed locally this session, not taken on faith): exact 95% upper bound = 1 − 0.05^(1/n) gives n=100 → 2.9513%, n=300 → 0.9936%, n=1000 → 0.2991%. So "300 samples all present ⇒ ≤1% miss rate at 95% confidence" is correct and mildly conservative. [hanley-rule-of-three]
- THE FATAL MISUSE, stated by PCAOB AS 2315 ¶.11: "confirming recorded receivables cannot be relied on to reveal unrecorded receivables." Sampling from the copy you HOLD can never detect items never copied. The sample frame must be drawn source-side (or from an independently obtained manifest), or the inference is void at any n. [pcaob-as2315]
- Stratification is the audit-standard answer to clustered defects. PCAOB AS 2315 ¶.22: separate the population "into relatively homogeneous groups… **An appropriate number of items is then selected from each group.**" ¶.24 requires that "**all items in the population should have an opportunity to be selected**" — the formal name for "don't sample only recent items". [pcaob-as2315]
- PCAOB ¶.21 blesses a hybrid: examine 100% the items where "acceptance of some sampling risk is not justified", and "**Any items that the auditor has decided to examine 100 percent are not part of the items subject to sampling.**" [pcaob-as2315]
- Under genuinely uniform sampling, clustering does NOT break the marginal zero-defect bound (a contiguous 5% gap still has 5% hit probability per draw). What clustering breaks is (a) non-uniform sampling, (b) variance once a defect IS found, and (c) per-stratum claims — "≤1% overall" is compatible with "one entire channel 100% missing" if that channel is 1% of volume. [pcaob-as2315] [koenderks-stratified]
- Stratified evaluation offers three aggregation choices — no pooling, complete pooling, partial pooling — where "Complete pooling assumes no difference between strata". Pooling is exactly the assumption a clustered bug violates, so no-pooling (report the worst stratum) is the honest default. [koenderks-stratified]
- ISO 2859-1 / ANSI-ASQ Z1.4 acceptance sampling is real prior art but a poor fit: its stated purpose is "to incentivize the producer through the economic and psychological pressure of lot non-acceptance" — an economic feedback loop on a supplier you have leverage over, presupposing a discrete lot you can reject as a unit. Neither holds for a personal-data archive. [iso-2859-ansi]

### Who actually ships sampled or cheap verification

- restic `--read-data-subset` is the one widely-deployed tool shipping probabilistic verification. It has three forms. `n/t` is a DETERMINISTIC partition: "all pack files in the repository are logically divided in `t` (roughly equal) groups, and only files that belong to group number `n` are checked" — run all t and coverage is 100%. The percentage form is random and explicitly guarantees nothing: "**This will not guarantee to cover all available pack files after sufficient runs**, but it is easy to automate checking a small subset of data after each backup." [restic-check]
- restic's docs state NO numeric cadence recommendation (no "1% weekly") — only "it's a good idea to regularly use the `check` command". Absence noted rather than invented. [restic-check]
- Datafold data-diff implements checksum-per-segment bisection: "data-diff splits the table into smaller segments, then checksums each segment in both databases. When the checksums for a segment aren't equal, it will further divide that segment… until it gets to the differing row(s)", with performance "within an order of magnitude of `count(*)` when there are few/no changes". Cost is ~O(bisection_factor × log_f(N)) queries returning scalars, not rows. DISQUALIFIER: it requires the remote to execute arbitrary aggregate SQL including `md5()` over a key range. Repo archived read-only 2024-05-17. [datafold-data-diff]
- data-diff degrades badly on sparse keys: "If there are very large gaps in your key column… then data-diff may perform poorly, doing lots of queries for ranges of rows that do not exist." [datafold-data-diff]
- dbt-utils ships `equal_rowcount` ("Asserts that two relations have the same number of rows"), `fewer_rows_than`, and `equality`, all supporting `group_by_columns` — which is the stratification hook (equal_rowcount grouped by month = a per-time-bucket count check). Constraint: `ref()`-based, so both relations must live in the same warehouse. [dbt-utils]
- S3 Inventory is the provider-manifest cooperation model: CSV/ORC/Parquet object lists "on a **daily or weekly** basis", and critically "does not use the `List` API operations to audit your objects and **does not affect the request rate of your bucket**" — a manifest that costs nothing against the API budget. Optional ETag and Size fields enable content-level comparison. [s3-inventory]
- S3 Inventory documents its own staleness: it "provides **eventual consistency**… a list might not include recently added or deleted objects", up to 48 hours for the first report, and recommends a live `HeadObject` "To validate the state of an object before you take action". [s3-inventory]
- Glacier vault inventory updates "at least once per day" and returns "a **point-in-time snapshot and not real-time data**". AWS describes this use case in nearly PDPP's words: "suppose you maintain a database on the client-side associating metadata about the archives… you might find the vault inventory useful to **reconcile information… in your database with the actual vault inventory**." Supports range inventory retrieval filtered by archive creation date — a native stratification hook. [glacier-inventory]
- Financial reconciliation is exhaustive by construction and achieves it via a CONTROL TOTAL: Stripe's Balance report works so that "Like a bank account, the balance is reconciled at the end of the period to confirm that all transactions have been accounted for." An O(1) aggregate certifies an O(n) population. ("Three-way reconciliation" is practitioner vocabulary; it does not appear in Stripe's docs.) [stripe-reports]
- NEGATIVE RESULT: sampling-based verification of a remote copy is RARE in shipped software. Across backup, data-quality, cloud-storage and payments, restic `--read-data-subset` was the only widely-deployed instance found — and even it verifies data it wrote itself against hashes it computed itself. What people do instead, in preference order: control totals → provider-issued manifests → segment checksums with bisection → full comparison in one place → sampling as last resort. The reason is structural: the first three all require cooperation from the other side, and sampling is what remains when there is none. [restic-check] [s3-inventory] [stripe-reports] [datafold-data-diff]

## SOURCES

**restic-check**
URL: https://raw.githubusercontent.com/restic/restic/master/doc/045_working_with_repos.rst (canonical source of https://restic.readthedocs.io/en/stable/045_working_with_repos.html; readthedocs returned HTTP 429)
Accessed: 2026-08-19
Quote: "Use ``--read-data-subset=x%`` to check a randomly chosen subset of the repository pack files… This will not guarantee to cover all available pack files after sufficient runs, but it is easy to automate checking a small subset of data after each backup."

**restic-backup**
URL: https://raw.githubusercontent.com/restic/restic/master/doc/040_backup.rst
Accessed: 2026-08-19
Quote: "Restic cannot detect if data read from stdin is complete or not. As explained below, this can cause incomplete backup unless additional checks (outside of restic) are configured."

**borg-check**
URL: https://raw.githubusercontent.com/borgbackup/borg/master/docs/usage/check.rst.inc (the `.rst` page is an `.. include::` stub; substance lives in `.rst.inc`)
Accessed: 2026-08-19
Quote: "Please note that partial repository checks (i.e., running with ``--max-duration``) can only perform non-cryptographic checksum checks on the repository files."

**rclone-check**
URL: https://rclone.org/commands/rclone_check/
Accessed: 2026-08-19
Quote: "If you supply the ``--download`` flag, it will download the data from both remotes and check them against each other on the fly. This can be useful for remotes that don't support hashes or if you really want to check all the data."

**zfs-scrub**
URL: https://openzfs.github.io/openzfs-docs/man/master/8/zpool-scrub.8.html
Accessed: 2026-08-19
Quote: "A normal scrub examines all data in the specified pools and verifies each block's checksum."

**aws-restore-testing**
URL: https://docs.aws.amazon.com/aws-backup/latest/devguide/restore-testing.html and .../restore-testing-validation.html
Accessed: 2026-08-19
Quote: "for each selected protected resource, AWS Backup restores at most one recovery point."

**cisa-3-2-1**
URL: https://www.cisa.gov/sites/default/files/publications/data_backup_options.pdf (Ruggiero & Heckathorn, CMU SEI, produced for US-CERT, 2012)
Accessed: 2026-08-19
Quote: "Rolling backups can silently propagate any corruption or malware in the primary files to the backup files."

**cassandra-repair**
URL: https://cassandra.apache.org/doc/stable/cassandra/managing/operating/repair.html
Accessed: 2026-08-19
Quote: "It compares the data with merkle trees, which are a hierarchy of hashes."

**cassandra-source**
URL: Apache Cassandra `trunk` — `DatabaseDescriptor.java`, `ValidationManager.java`, `MerkleTree.java`
Accessed: 2026-08-19
Quote: "Performs a readonly 'compaction' of all sstables in order to validate complete rows, but without writing the merge result."

**dynamo-paper**
URL: https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf (§4.7)
Accessed: 2026-08-19
Quote: "The disadvantage with this scheme is that many key ranges change when a node joins or leaves the system thereby requiring the tree(s) to be recalculated."

**rsync-tech-report**
URL: https://rsync.samba.org/tech_report/node2.html
Accessed: 2026-08-19
Quote: "For each of these blocks β calculates two checksums: a weak 'rolling' 32-bit checksum… and a strong 128-bit MD4 checksum. β sends these checksums to α."

**syncthing-bep**
URL: https://docs.syncthing.net/specs/bep-v1.html
Accessed: 2026-08-19
Quote: "Each device has one or more folders of files described by the local model, containing metadata and block hashes. The local model is sent to the other devices in the cluster."

**imap-rfc9051**
URL: https://www.rfc-editor.org/rfc/rfc9051.html (§2.3.1.1, §6.3.11)
Accessed: 2026-08-19
Quote: "Unique identifiers are assigned in a strictly ascending fashion… Unlike message sequence numbers, unique identifiers are not necessarily contiguous."

**imap-rfc7162**
URL: https://www.rfc-editor.org/rfc/rfc7162.html
Accessed: 2026-08-19
Quote: "A server that receives a mod-sequence smaller than <minmodseq>… MUST behave as if it was requested to report all expunged messages from the provided UID set parameter."

**carddav-rfc6578**
URL: https://www.rfc-editor.org/rfc/rfc6578.html (§3.2, §3.4, §3.5)
Accessed: 2026-08-19
Quote: "When the DAV:sync-collection request contains an empty DAV:sync-token element, the server MUST return all member URLs of the collection… and it MUST NOT return any removed member URLs."

**gmail-getprofile**
URL: https://developers.google.com/gmail/api/reference/rest/v1/users/getProfile and .../users.messages/list
Accessed: 2026-08-19
Quote: "Estimated total number of results."  (on `resultSizeEstimate`)

**gmail-history**
URL: https://developers.google.com/gmail/api/guides/sync
Accessed: 2026-08-19
Quote: "typically available for at least one week and often longer. However, the time period… may be significantly less"

**people-synctoken**
URL: https://developers.google.com/people/api/rest/v1/people.connections/list
Accessed: 2026-08-19
Quote: "only the resources changed since the last request" / "The total number of items in the list without pagination"

**slack-conversations**
URL: https://api.slack.com/methods/conversations.history and https://api.slack.com/methods/conversations.list
Accessed: 2026-08-19
Quote: (documented ABSENCE — no total-message-count field is defined in the response schema)

**hanley-rule-of-three**
URL: https://jhanley.biostat.mcgill.ca/c607/ch08/zero_numerator.pdf (Hanley JA, Lippman-Hand A, JAMA 1983;249(13):1743-1745)
Accessed: 2026-08-19
Quote: "if none of n patients shows the event about which we are concerned, we can be 95% confident that the chance of this event is at most three in n (ie, 3/n)."

**pcaob-as2315**
URL: https://pcaobus.org/oversight/standards/auditing-standards/details/AS2315
Accessed: 2026-08-19
Quote: "confirming recorded receivables cannot be relied on to reveal unrecorded receivables." / "An appropriate number of items is then selected from each group."

**koenderks-stratified**
URL: https://koenderks.github.io/sasr/chap-stratified-evaluation.html
Accessed: 2026-08-19
Quote: "Complete pooling assumes no difference between strata"

**iso-2859-ansi**
URL: https://blog.ansi.org/ansi/iso-2859-1-2026-aql-sampling/ (iso.org itself returned 403; standard text not read)
Accessed: 2026-08-19
Quote: "to incentivize the producer through the economic and psychological pressure of lot non-acceptance"

**datafold-data-diff**
URL: https://github.com/datafold/data-diff/blob/master/docs/technical-explanation.md (repo archived read-only 2024-05-17)
Accessed: 2026-08-19
Quote: "data-diff splits the table into smaller segments, then checksums each segment in both databases."

**dbt-utils**
URL: https://raw.githubusercontent.com/dbt-labs/dbt-utils/main/README.md
Accessed: 2026-08-19
Quote: "Asserts that two relations have the same number of rows."

**s3-inventory**
URL: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html
Accessed: 2026-08-19
Quote: "Amazon S3 Inventory does not use the `List` API operations to audit your objects and does not affect the request rate of your bucket." / "The inventory list provides eventual consistency"

**glacier-inventory**
URL: https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html
Accessed: 2026-08-19
Quote: "a point-in-time snapshot and not real-time data"

**stripe-reports**
URL: https://docs.stripe.com/reports/select-a-report
Accessed: 2026-08-19
Quote: "Like a bank account, the balance is reconciled at the end of the period to confirm that all transactions have been accounted for."

**eppstein-iblt**
URL: Eppstein, Goodrich, Uyeda, Varghese, "What's the Difference? Efficient Set Reconciliation without Prior Context", SIGCOMM 2011
Accessed: 2026-08-19
Quote: "stored at two distinct hosts and attempt to compute the set difference with minimal communication, computation, storage, and latency"

**meyer-range-reconciliation**
URL: https://github.com/AljoschaMeyer/set-reconciliation
Accessed: 2026-08-19
Quote: "When an endpoint receives a fingerprint for a range… it quickly computes the fingerprint over its local items in the same range"

## SYNTHESIS

### The one-sentence finding

There is no technique that proves completeness against an uncooperative source. Everything that makes verification cheap — Merkle trees, rsync deltas, IBFs, segment checksums — buys its savings by making the *other side* compute under a scheme *you* chose, and a consumer platform will never do that. What remains for a one-sided client is a short, honest list: internal consistency, watermark regression, sequence-gap detection, and sampling against a source-drawn frame. Anything better must be *volunteered* by the provider (a total, a manifest, a `VANISHED` list), and the correct engineering move is to harvest those volunteered facts aggressively where they exist and to say "unverified" where they don't.

### Ranked technique table

Ordered by value-per-cost for a client that cannot change the upstream.

| # | Technique | Catches | Misses | Cost | Upstream requirement | Ships it |
|---|---|---|---|---|---|---|
| 1 | **Control total** (provider count vs local count) | Any net shortfall in a stratum; the single cheapest real proof | Equal-count-but-wrong-contents; compensating loss+gain | 1 call/stream/run | Provider exposes a count. IMAP `STATUS`, Gmail `messagesTotal`. Slack/CardDAV: none | Stripe balance reconciliation; IMAP clients |
| 2 | **Boundary/watermark check** (oldest & newest held vs upstream) | Truncation at either end — the entire "cursor seeded wrong" class | Interior holes; anything between the two ends | 2 calls/stream/run (first page asc + desc) | Provider supports a sort or an ascending query. Slack has it cheaply; CardDAV doesn't | rclone `+` category (analogous) |
| 3 | **Watermark regression** (persisted max-id/epoch goes backwards) | Identifier-space resets; re-seeded connections | Everything else | Zero extra calls — pure local | Only ascending ids, which you already store | IMAP `UIDVALIDITY` (the canonical form) |
| 4 | **Internal consistency** (dupes, dangling refs, schema violations) | Corruption you introduced; broken invariants | Anything never fetched | Zero extra calls — pure local | None | restic/borg `check`, `zpool scrub` |
| 5 | **Sequence-gap detection** (holes in monotonic ids) | Provable holes without any upstream call — where ids are DENSE | Nothing, where ids are sparse (IMAP UIDs, Gmail historyId are both explicitly non-contiguous) | Zero extra calls — pure local | Dense monotonic ids. **Rarer than it looks** | — |
| 6 | **Stratified sampling** (N random source-side draws per time bucket) | Clustered interior loss; the only technique that catches an arbitrary hole | Probabilistic only; nonsampling risk (a bad oracle) | N calls/stratum/period | Only ordinary listing — **works against a hostile API** | restic `--read-data-subset`; AWS restore testing |
| 7 | **Provider manifest diff** | Everything, exactly, as a set difference | Items inside the manifest's staleness window | 1 manifest fetch | Provider issues a manifest. **No consumer platform does** | S3 Inventory, Glacier |
| 8 | **Server-side delta with tombstones** (`VANISHED`) | Deletions you never witnessed | Nothing, when available | 1 call | Server implements QRESYNC-class extension | IMAP/RFC 7162 |
| 9 | **Segment checksum bisection** | Everything, at ~count(*) cost | — | O(log n) queries | Remote runs your `md5()` over key ranges. **Disqualified for consumer APIs** | Datafold data-diff |
| 10 | **Merkle / IBF / range reconciliation** | Everything | — | O(dataset) to build | Remote hashes under your partitioning + canonicalization. **Disqualified** | Cassandra, Dynamo, rsync, Syncthing |

Rows 3-5 are free and should be unconditional. Rows 1-2 are one or two calls and should be default-on wherever the provider allows. Row 6 is the only thing that works when rows 1-2 are unavailable. Rows 7-10 are the cooperation PDPP cannot buy — worth naming explicitly so nobody re-litigates them.

### Recommended tier structure

**Tier 0 — every run, zero marginal API cost.** Watermark regression, internal consistency, sequence-gap scan. These are local computation over data already held. The rule: a run may not report coverage without them.

**Tier 1 — every run, 1-3 calls per stream.** Control total where the provider offers one; boundary check (oldest + newest) always. Compare against local. Any mismatch downgrades the stream and names the delta.

**Tier 2 — periodic (weekly), bounded cost.** Stratified sampling with a *deterministic rotating partition*, not repeated random draws. This is restic's `n/t` lesson: same per-run cost, but coverage accumulates to 100% instead of asymptoting. Stratify by time bucket so a cursor-truncation bug cannot hide, and per PCAOB ¶.21 verify small strata 100% rather than sampling them (a 40-message channel is cheaper to check exhaustively).

**Tier 3 — on demand / escalation.** Full re-enumeration. Triggered by a Tier 0-2 failure, a credential repair, a connection re-seed, or an owner request. Expensive and rate-limit-burning; must be a deliberate act.

**Escalation trigger:** any Tier 0-2 disagreement escalates one tier. This mirrors Borg's `--max-duration` amortization and AWS's scheduled restore testing.

### The cheapest check that would have caught each live failure

- **ChatGPT re-seeded cursor (2023: 39 of 826).** Tier 1 boundary check, ~1 extra call: ask the source for its OLDEST conversation and compare to the oldest held. The seeded high-water mark made everything older unreachable, so the oldest-held would have been wildly newer than the oldest-upstream on the very first run. Failing that, Tier 0 watermark regression would have fired for free the moment a cursor was inherited that was *newer* than the connection's own history — a re-seed is exactly an identifier-space reset, which is what `UIDVALIDITY` exists to catch. And if only sampling were available: the miss rate in the 2023 stratum was 95.3%, so **3 stratified draws from 2023 detect it with 99.99% probability** (verified: 1 − (39/826)³). This is the strongest argument in the whole report for time-stratification — a global uniform sample would also have caught it, but only stratification *guarantees* the old bucket gets drawn.

- **Apple Contacts empty change-feed read as empty inventory.** Tier 1 control total is unavailable (CardDAV defines no count). The correct fix is not a check at all but a *declaration*: RFC 6578 states normatively that a non-empty sync-token returns only changed members, and PDPP's `apple_contacts.contacts` stream declares `coverage_strategy: "full_inventory"` while the code path that ran was `syncCollectionReport` — a delta. **The cheapest catch is a build-time assertion that a stream declaring full-inventory coverage may not source its coverage evidence from a delta call**, costing zero API calls. The runtime backstop is equally cheap: a delta response may only ever *adjust* a held inventory count, never *establish* one; a first-ever run with no prior inventory must fall back to the empty-token full listing the RFC already mandates.

The pattern across both: neither failure needed a clever verification technique. Both needed the system to distinguish "I fetched everything that exists" from "I processed everything I fetched" — which is a *type* distinction, not a measurement.

### Proposed connector-capability taxonomy

PDPP's existing `coverage_strategy` (`checkpoint_window`, `full_inventory`, `parent_detail_accounting`, `snapshot_import_receipt`, `singleton_presence`) describes **how the run walks the source**. It does not describe **how a claim is checked**, which is why 82 of 83 streams satisfy `covered == considered` by construction. These are two orthogonal axes and the fix is to add the second, not to overload the first.

Proposed `verification` block, per stream. Every field is grounded in an affordance a real API was confirmed to have or lack:

```
verification:
  total:      none | exact | estimated        # IMAP STATUS=exact; Gmail messagesTotal=exact;
                                              # Gmail resultSizeEstimate=estimated; Slack=none
  boundary:   none | newest | oldest | both   # Slack=both (oldest=0 is cheap); CardDAV=none
  sequence:   none | sparse | dense           # IMAP UID=sparse (explicitly non-contiguous);
                                              # Gmail historyId=sparse. dense is RARE — do not assume
  delta:      none | changes_only | changes_with_tombstones
                                              # CardDAV/People=changes_with_tombstones;
                                              # IMAP QRESYNC=changes_with_tombstones + VANISHED
  inventory_call: none | <named full-listing path>
                                              # the empty-token full listing RFC 6578 mandates
  sampling:   none | by_id | by_stratum       # can I re-fetch an arbitrary known id? by_stratum
                                              # needs a date-range or sort query
```

Four rules make this load-bearing rather than decorative:

1. **`total: estimated` may never satisfy a completeness claim.** It can only trigger investigation. Gmail ships both an exact and an estimated count; conflating them is a live hazard.
2. **`sequence: sparse` may never be used for gap detection.** Both IMAP UIDs and Gmail historyIds are documented non-contiguous; a hole is a question, not a defect. This field's main job is to *forbid* an attractive wrong inference.
3. **`delta` is not `inventory_call`.** A stream whose only coverage source is a `delta` call may not declare `full_inventory` coverage. This is the Apple Contacts bug expressed as a schema constraint, checkable at build time by the existing `stream-evidence-strategy-manifest.test.ts` guardrail.
4. **All-`none` is legal and must be declarable.** ChatGPT has no API at all. Forcing every stream to claim a capability is how you get the fiction PDPP has now.

### The honest state when nothing is verifiable

Mature systems do not fabricate a verdict; they name the ignorance and make it a peer of the other states. The prior art is consistent:

- Kubernetes Conditions use `True | False | Unknown`, where `Unknown` means "we haven't heard", and absence reads the same as `Unknown` (established in the 2026-08-16 corpus entry).
- The Nagios plugin guideline separates UNKNOWN ("the check itself could not run") from CRITICAL ("the check ran and found a bad state").
- IMAP refuses to guess: a server without persistent mod-sequences returns `NOMODSEQ` rather than an empty delta.
- rclone keeps `!` (error reading or hashing) as a distinct category from `=` (match) — it never folds an unrunnable check into a pass.

So the state PDPP needs is **`unverified`**, and it is not a failure state. It says: the data we hold is what we collected, and this source offers no way to confirm that is everything. It must be visually and semantically distinct from `verified_complete` and from `verified_incomplete`. The current design's sin is that it has only one of these three and applies it to all cases. Note the copy consequence, which the existing ux-writing corpus entry already settles: permanent unverifiability is a *standing fact*, so it takes the future declarative tense ("This source cannot confirm completeness"), not the retryable past tense.

### What I could NOT find prior art for

Stated plainly so the next person doesn't re-search it:

1. **No consumer personal-data product verifies completeness against upstream.** Not one. This is white space, consistent with a prior corpus finding that "no connector ecosystem verifies function."
2. **No one-sided completeness proof exists, anywhere.** This is a structural result, not a gap in my search: the three-part conjunction (execute your code, agree on your partitioning, agree on your canonicalization) is unsatisfiable against an API you don't control.
3. **No numeric cadence guidance for sampled verification.** restic ships the mechanism and explicitly declines to recommend a percentage or interval. Borg gives one worked example (7-hour check ÷ 1 hour/day = weekly) and no principle. Any interval PDPP picks is an invention, and should be labeled as one.
4. **No standard vocabulary for "verifiable capability" of an API.** Nothing like an OpenAPI extension for "this endpoint gives an exact total". The taxonomy above is synthesized from observed affordances, not adopted from a standard.
5. **The "untested backup is not a backup" maxim has no primary source** in the documents fetched, including CISA's.
6. **Google People `totalItems` under a syncToken is undocumented** — the docs are silent on whether it counts the delta or the collection. This is unresolvable from documentation and would need empirical testing against the live API.

### Per-claim confidence, and what would falsify it

| Claim | Confidence | Falsified by |
|---|---|---|
| restic/borg/zfs checks are repository-vs-itself and cannot detect a missed source | **Very high** — restic's stdin warning concedes it in vendor words | A documented source-comparison mode in any of the three |
| Every Merkle/set-reconciliation scheme is two-sided | **Very high** — 5 independent primary sources, no counterexample | A named technique proving remote-set completeness with only ordinary listing calls |
| RFC 6578 empty-token = full inventory, non-empty = delta only | **Very high** — normative MUST, quoted | Nothing plausible; it's RFC text |
| IMAP UIDs are strictly ascending but NOT contiguous | **Very high** — normative, quoted, and independently confirmed by two agents | Nothing plausible |
| Rule of three: n=300 ⇒ ≤1% at 95% | **Very high** — primary source AND recomputed locally this session | Arithmetic error (recheck 1−0.05^(1/300)=0.9936%) |
| 3 draws from the 2023 stratum detect the ChatGPT bug at 99.99% | **High** — arithmetic verified; depends on the reported 39/826 being accurate | The parallel forensics agent finding different real numbers |
| Slack exposes no total-message count | **Medium-high** — documented absence, harder to prove than presence; scoped to the standard Conversations API, NOT Grid Discovery/Audit APIs | Any total field in conversations.* response schemas |
| Google People `totalItems` is ambiguous under syncToken | **Medium** — this is a claim about documentation SILENCE | Google clarifying it, or an empirical test settling it |
| Cassandra Merkle depth ~15-20, memory-capped | **Medium** — version-dependent; trunk default is 20, pre-4.0 was 15 | Reading a specific deployed version's config. The load-bearing part (leaf covers a token RANGE, so mismatches over-stream) is version-independent |
| ISO 2859-1 is a poor fit here | **Medium** — reasoning is sound but iso.org 403'd, so the standard's own text was not read | Reading the actual standard |
| No consumer personal-data product verifies completeness upstream | **Medium** — absence-of-evidence over a broad space | One counterexample product |
| GX multi-source Expectation caps at 200 rows | **Low — SEARCH-SUMMARY only, do not cite** | Reading GX docs directly |

Two methodological caveats an attacker should know: readthedocs returned HTTP 429 throughout, so restic and Borg were read from the upstream `.rst`/`.rst.inc` sources that generate those pages rather than the rendered pages; and one delegated fetch initially hallucinated a single-sided IBF mode, which was caught and refuted by reading the paper's pages directly — treat any single-sided set-reconciliation claim as false unless quoted from a primary source.
