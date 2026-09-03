---
title: "Consumer sync products almost never model 'working AND permanently partially incomplete' — Nextcloud's SyncResult::Problem tier ('Sync was successful but some files were ignored') is the only shipped success-with-a-permanent-gap state found, finished one-time imports are universally an EVENT not a STATE, and no product ships a fused 'last updated X · syncing now' string"
date: 2026-08-19
topic: ux-writing
tags: [status-copy, permanently-partial, one-time-import, mid-sync, consumer-vocabulary, connector-health, negative-finding]
status: draft
sources: [nc-theme-cpp, nc-syncstatussummary-cpp, nc-accountsettings-cpp, nc-translations-ts, syncthing-lang-en, syncthing-index-html, immich-en-json, bitwarden-messages-json, obsidian-importer-i18n, photoprism-en-po, firefly-lang-php, dropbox-sync-icons, onedrive-cant-sync, gdrive-sync-problems, 1password-watchtower-fetch, nc-issue-2402, nc-forum-ignored-log, takeout-manage-exports, monarch-manual-accounts]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Builds on, does not repeat:
- product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md  (READ FIRST — settles
  "do consumer products show condition lists": YES, filtered to non-passing rows. Not redone here.)
- product-design/data-possession-and-work-in-flight-are-orthogonal-axes-...md   (two-axis TanStack/SWR,
  RFC 5861 labeled-and-bounded staleness, actor-not-tone owner/maintainer split.)
- api-contract-design/health-vocabularies-separate-a-lifecycle-axis-...md       (k8s condition schema,
  GitHub two-axis, ELB non-failure enum slots, unknown-vs-not_applicable.)
- feedback-systems/integration-health-ui-converges-on-one-synthesized-verdict-...md

This entry answers the NARROWER question those four leave open: what EXACT WORDS a consumer
product puts on screen for a source that is simultaneously (a) mostly working, (b) mid-sync,
and (c) permanently partially broken. Deliverable is a verbatim vocabulary, not a survey.
-->

## CLAIMS

### The "permanently partial" tier — Nextcloud is the only shipped example

- Nextcloud's desktop client has a **three-member success/failure vocabulary in which partiality is a named peer of success and error**, not a subtype of error. `Theme::statusHeaderText` switches on `SyncResult::Status` and emits: `Success` → "Sync was successful"; `Problem` → **"Sync was successful but some files were ignored"**; `Error` → "Error occurred during sync". `SyncResult::Problem` is a distinct enum member from both `Success` and `Error`. [nc-theme-cpp]
- The same `SyncResult::Problem` state drives a distinct icon and a distinct summary line in the tray/activity surface: `setSyncStatusString(tr("Some files could not be synced!"))`, `setSyncStatusDetailString(tr("See below for warnings"))`, `setSyncIcon(Theme::instance()->warning())`. The `Error` branch is worded almost identically — `"Some files couldn't be synced!"` / `"See below for errors"` / `error()` icon. The two differ only by an apostrophe-contraction, the words warnings-vs-errors, and the icon. [nc-syncstatussummary-cpp]
- Nextcloud's fully-healthy resting string is `tr("All synced!")` with `Theme::instance()->ok()`, and it is gated on there being no folder errors at all: the source comment reads "Success should only be shown if all folders were fine". [nc-syncstatussummary-cpp]
- Nextcloud renders a `SyncResult::Undefined` (no status yet) as the optimistic resting state rather than as a failure, with an explicit in-source rationale: "It means \"no status yet\", not \"a sync failed\", so render it as the optimistic resting state rather than the misleading \"Some files could not be synced!\"" — citing a real bug, nextcloud/desktop#10053. [nc-syncstatussummary-cpp]
- Nextcloud states a **size-cap exclusion as a plain fact with the affected items listed inline and no error framing**: `tr("There are folders that were not synchronized because they are too big: ")` followed by the folder list, plus sibling variants `"...because they are external storages: "` and `"...because they are too big or external storages: "`, and a separate `tr("There are folders that have grown in size beyond %1MB: %2")`. [nc-accountsettings-cpp][nc-translations-ts]
- These size-cap strings render into `_ui->selectiveSyncNotification->setText(infoString)` — a **persistent notification widget on the Account Settings pane**, not a one-time modal consent prompt. The surrounding code distinguishes two populations by checking the selective-sync blacklist: folders already blacklisted go into `unsyncedFoldersString` ("were not synchronized because they are too big"), while folders that crossed the threshold after the fact go into `becameBigFoldersString` ("have grown in size beyond %1MB"). [nc-accountsettings-cpp]
- Nextcloud phrases **permanent exclusions in the future declarative** and **retryable failures in the past tense with a log pointer**. Permanent: "The file %1 was created but was excluded from synchronization previously. It will not be synchronized." and "The folder %1 was created but was excluded from synchronization previously. Data inside it will not be synchronized." Retryable: "%1 could not be synced due to an error. See the log for details." and "%1 and %n other file(s) could not be synced due to errors. See the log for details." [nc-translations-ts]
- Nextcloud names a deliberate-exclusion reason in owner-legible terms: "Ignored because of the \"choose what to sync\" blacklist", alongside the mechanism-level "The filename is blacklisted on the server." and a size string "The file is too big to upload. You might need to choose a smaller file or contact your server administrator for assistance." [nc-translations-ts]
- The known weakness of Nextcloud's design is that the warning tier is reachable but its **item list is not**: a Nextcloud community thread titled "Where to find a full log of ignored files" reports hovering an account yields the hover text "Sync was successful but some files were ignored" while the activity list shows only log-in/changed/deleted/added activity, with no enumeration of the ignored files. [nc-forum-ignored-log]

### Syncthing — count-plus-drill-in, and an explicitly retryable failed-items list

- Syncthing's folder-status table exposes three separate itemized rows, each rendered as a **count that is a link opening the list**: "Out of Sync Items" (`showNeed`), "Failed Items" (`showFailed`), "Locally Changed Items" (`showLocalChanged`). The template carries the comment "Show the number of failed items as a link to bring up the list." [syncthing-index-html]
- Syncthing's failed-items panel copy is **explicitly retryable, which disqualifies it as a permanent-gap model**: "The following items could not be synchronized." followed by "They are retried automatically and will be synced when the error is resolved." [syncthing-lang-en]
- Syncthing's state vocabulary is: "Up to Date", "Syncing", "Scanning", "Preparing to Sync", "Waiting to Sync", "Waiting to Scan", "Out of Sync", "Paused", "Paused (Unused)", "Stopped", "Unshared", "Unknown", "Cleaning Versions", "Waiting to Clean". "Last Scan" is a separately-labeled timestamp field, not fused into the state string. [syncthing-lang-en]
- Syncthing annotates a **deliberately-reduced count in place** with a clickable link, rather than treating the reduction as a failure: when `ignorePatterns` is set, the folder's local-state line renders `<i>Reduced by ignore patterns</i>` as an anchor whose click opens the ignore-pattern editor (`editFolderExisting(folder, '#folder-ignores')`). A sibling string does the same for a different policy: "Altered by ignoring deletes." with a "Help" link. [syncthing-index-html][syncthing-lang-en]

### Mid-sync — no product ships a fused "last updated X · syncing now" string

- Nextcloud's in-progress copy is item-count-based with an optional time-remaining clause: "Syncing %1 of %2", "Syncing %1 of %2  (%3 left)", "Syncing %1 of %2 (A few seconds left)", "Syncing file %1 of %2", "%1 of %2 · %3 left", "%1 of %2, file %3 of %4", "%5 left, %1 of %2, file %3 of %4", "A few seconds left, %1 of %2, file %3 of %4". [nc-translations-ts]
- Nextcloud's in-progress summary strings replace rather than augment the resting state: `SyncRunning`/`NotYetStarted` set `tr("Checking folder changes")` when `totalFiles() <= 0` and `tr("Syncing changes")` otherwise, with `setSyncStatusDetailString("")` — the detail line is explicitly blanked. [nc-syncstatussummary-cpp]
- Immich's backup notification strings are sequential state replacements, not composed: "Checking for new assets…" → "Backing up your assets…" → "Asset backup complete". Immich's remaining-work counter is labeled "Remainder" with sub-label "Remaining photos and videos to back up from selection". [immich-en-json]
- Nextcloud's icon-only in-progress signalling is a **documented UX failure**: nextcloud/desktop issue #2402 is titled "Status icon in taskbar shows client fully synced while sync is actually running." [nc-issue-2402]
- Dropbox's desktop status strings are state-replacing, per its official help pages: "Your files are up to date", "Indexing", "Syncing [file name]", "Syncing [x] files", "Syncing paused until [x]", "[x] files are unable to sync". [dropbox-sync-icons]
- Across the four codebases/products whose strings were read at source level (Nextcloud, Syncthing, Immich, Dropbox), **no string was found that fuses a last-known-good timestamp with an in-flight verb in one sentence**. Freshness and activity are carried either as two separate labeled UI fields (Syncthing: state field + "Last Scan" field) or by state replacement (Nextcloud, Immich, Dropbox). [nc-translations-ts][syncthing-lang-en][immich-en-json][dropbox-sync-icons]
- No timeout/stuck-sync copy string was found in any surveyed string file. The only evidence on stuck syncs is bug reports describing the *absence* of good handling. [nc-issue-2402]

### Finished one-time imports — an EVENT, never a STATE

- Bitwarden's import completion is a transient toast: `"importSuccess": "Data successfully imported"` and `"importSuccessNumberOfItems": "A total of $AMOUNT$ items were imported."` No persistent "imported" tag, category, or status field was found in the locale file; imported items merge indistinguishably into the vault. [bitwarden-messages-json]
- PhotoPrism's import completion is likewise transient: "Import completed in %d s", "Importing files to originals…", "Import canceled", "Import failed". Imported files become ordinary photos with no surviving import badge. [photoprism-en-po]
- Obsidian Importer's completion record is an **ordinary artifact, not a status object**: `msgComplete: 'Import complete.'`, `msgFinished: 'Finished {{when}}. {{counts}}.'`, `title: '{{importer}} import'`, `fileName: '{{date}} {{importer}} import log'` — a deletable Markdown note dropped into the vault. The imported content itself carries no marking. [obsidian-importer-i18n]
- Firefly III, a finance app whose account list can hold both CSV-loaded and bridge-fed accounts, uses **no import-specific or sync-specific vocabulary at all** at the account-list level: the status pair is `'active' => 'Active'` / `'inactive' => 'Inactive'` and the timestamp column is `'account_column_opt_last_activity' => 'Last activity'` — a generic label, not "Last synced". [firefly-lang-php]
- Google Takeout structurally avoids the finished-import-forever problem: completed archives live under a "Manage Exports" view, expire after roughly 7 days, and Takeout does not retain a record of exports after expiry. [takeout-manage-exports]
- 1Password Watchtower's "Imported from LastPass" is **not** a general finished-import status — it is a breach-warning category. The support page's heading is "Identify vulnerable logins imported from LastPass" and the body reads "Imported from LastPass are logins that may have been compromised in a breach that LastPass experienced in August 2022." The Watchtower page headings are task-phrased imperatives ("Find compromised websites and vulnerable passwords", "Identify reused and weak passwords", "Find unsecured websites", "Check for expiring items", "Find duplicate items", "Check for developer secrets on disk"), not dashboard chip labels; the page does not state what the dashboard shows when a category is empty. [1password-watchtower-fetch]
- Monarch Money names a persistent "Manual Accounts" category distinct from connected/synced accounts, and documents uploading balance history into manual accounts — i.e. a one-time-loaded account living in the same list as live-synced accounts. Exact on-screen list copy could not be retrieved (help centre returned HTTP 403). [monarch-manual-accounts]

### Permanent-vs-retryable is collapsed almost everywhere

- Dropbox uses one tooltip bucket covering both permanent and transient causes: "Your file can't update or sync". A separate deliberate-exclusion tooltip exists — "Your file is ignored and won't sync" — but it is opt-in and user-configured, not auto-detected. Dropbox's healthy states are "Your file is synced and available offline" / "Your file is synced and available online". [dropbox-sync-icons]
- OneDrive surfaces size-cap and transient failures with the same undifferentiated client-side error treatment. Its named conditions include "OneDrive can't upload this file", "This file is too big", "This file can't be synced", "This file can't be synced because OneDrive doesn't have permission to access the file", "This file is in use by another application". The dedicated "This file can't be synced" troubleshooting article does not mention file size caps; the size case lives on a different page with no cross-reference. [onedrive-cant-sync]
- Google Drive for desktop explicitly carves out only ONE retryable bucket — "Files exceed bandwidth, upload, or download limits", which "Drive for desktop will automatically retry later" — and routes other failures ("due to permissions, network errors, or other reasons") into a literal local **"Lost and Found"** folder, an undifferentiated catch-all that does not separate permanent-policy from transient-glitch. [gdrive-sync-problems]

## SOURCES

**nc-theme-cpp**
URL: https://raw.githubusercontent.com/nextcloud/desktop/master/src/libsync/theme.cpp
Accessed: 2026-08-19
Quote (`Theme::statusHeaderText`, ~:99-125): `case SyncResult::Success: ... "Sync was successful"` / `case SyncResult::Problem: ... "Sync was successful but some files were ignored"` / `case SyncResult::Error: ... "Error occurred during sync"` / `case SyncResult::Undefined: ... "Sync status is unknown"` / `case SyncResult::NotYetStarted: ... "Waiting to start syncing"` / `case SyncResult::SyncRunning: ... "Sync is running"` / `case SyncResult::SyncPrepare: ... "Preparing to sync"` / `case SyncResult::SyncAbortRequested: ... "Stopping sync"`
Note: Raw C++ source fetched and read directly by me. This is the load-bearing source for the whole entry.

**nc-syncstatussummary-cpp**
URL: https://raw.githubusercontent.com/nextcloud/desktop/master/src/gui/activity/syncstatussummary.cpp
Accessed: 2026-08-19
Quote (`setSyncState`, ~:206-276): `setSyncStatusString(tr("All synced!"))` with `Theme::instance()->ok()` for `Success`; `setSyncStatusString(tr("Some files couldn't be synced!")); setSyncStatusDetailString(tr("See below for errors")); setSyncIcon(Theme::instance()->error());` for `Error`/`SetupError`; `setSyncStatusString(tr("Some files could not be synced!")); setSyncStatusDetailString(tr("See below for warnings")); setSyncIcon(Theme::instance()->warning());` for `Problem`; `tr("Checking folder changes")` / `tr("Syncing changes")` for `SyncRunning`/`NotYetStarted`; `tr("Sync paused")` for `Paused`/`SyncAbortRequested`; `tr("Offline")` when not connected.
Quote (source comment): "It means \"no status yet\", not \"a sync failed\", so render it as the optimistic resting state rather than the misleading \"Some files could not be synced!\"" and "Success should only be shown if all folders were fine"
Note: Raw C++ source fetched and read directly by me.

**nc-accountsettings-cpp**
URL: https://raw.githubusercontent.com/nextcloud/desktop/master/src/gui/accountsettings.cpp
Accessed: 2026-08-19
Quote (~:1830-1850): `infoString += !cfg.confirmExternalStorage() ? tr("There are folders that were not synchronized because they are too big: ") : !cfg.newBigFolderSizeLimit().first ? tr("There are folders that were not synchronized because they are external storages: ") : tr("There are folders that were not synchronized because they are too big or external storages: ");` then `infoString += unsyncedFoldersString;` and `infoString += tr("There are folders that have grown in size beyond %1MB: %2").arg(folderSizeLimitString, becameBigFoldersString);` terminating in `_ui->selectiveSyncNotification->setText(infoString);`
Quote (source comment ~:1820): "The new big folder procedure automatically places these new big folders in the blacklist. This is not the case for existing folders discovered to have gone beyond the limit. So we need to check if the folder is in the blacklist or not and tweak the message accordingly."
Note: Raw C++ source fetched and read directly by me. This read CORRECTS a delegated agent's conclusion that the too-big string is a one-time pre-sync consent prompt — the widget is a persistent Account Settings notification.

**nc-translations-ts**
URL: https://raw.githubusercontent.com/nextcloud/desktop/master/translations/client_en_GB.ts
Accessed: 2026-08-19
Quote: "Sync was successful but some files were ignored" / "Sync was successful" / "Last sync was successful." / "Some files could not be synced!" / "Some files couldn't be synced!" / "Sync Running" / "Waiting to start syncing." / "Ignored because of the \"choose what to sync\" blacklist" / "The filename is blacklisted on the server." / "The file %1 was created but was excluded from synchronization previously. It will not be synchronized." / "The folder %1 was created but was excluded from synchronization previously. Data inside it will not be synchronized." / "%1 could not be synced due to an error. See the log for details." / "%1 and %n other file(s) could not be synced due to errors. See the log for details." / "%1 (skipped due to earlier error, trying again in %2)" / "The file is too big to upload. You might need to choose a smaller file or contact your server administrator for assistance." / "Disk space is low: Downloads that would reduce free space below %1 were skipped." / "Files Ignored by Patterns" / "Edit Ignored Files" / "Ignored Files Editor" / "Unresolved conflict."
Quote (progress format strings): "Syncing %1 of %2" / "Syncing %1 of %2  (%3 left)" / "Syncing %1 of %2 (A few seconds left)" / "Syncing file %1 of %2" / "%1 of %2 · %3 left" / "%1 of %2, file %3 of %4" / "%5 left, %1 of %2, file %3 of %4" / "A few seconds left, %1 of %2, file %3 of %4" / "About to start syncing"
Note: 423 KB Qt Linguist file fetched and grepped directly by me. `<location>` elements map strings to source files, which is how theme.cpp / syncstatussummary.cpp / accountsettings.cpp were located.

**syncthing-lang-en**
URL: https://raw.githubusercontent.com/syncthing/syncthing/main/gui/default/assets/lang/lang-en.json
Accessed: 2026-08-19
Quote: "The following items could not be synchronized." / "They are retried automatically and will be synced when the error is resolved." / "Failed Items" / "Out of Sync Items" / "Locally Changed Items" / "Reduced by ignore patterns" / "Altered by ignoring deletes." / "Up to Date" / "Syncing" / "Scanning" / "Preparing to Sync" / "Waiting to Sync" / "Waiting to Scan" / "Out of Sync" / "Paused" / "Paused (Unused)" / "Stopped" / "Unshared" / "Unknown" / "Last Scan" / "Sync Status" / "Receive Only"
Note: Fetched and grepped directly by me.

**syncthing-index-html**
URL: https://raw.githubusercontent.com/syncthing/syncthing/main/gui/default/index.html
Accessed: 2026-08-19
Quote (~:470-495): `<th>...<span translate>Out of Sync Items</span></th><td class="text-right"><a href="" ng-click="showNeed(folder.id)">...` / `<!-- Show the number of failed items as a link to bring up the list. -->` / `<a href="" ng-click="showFailed(folder.id)">{{model[folder.id].pullErrors | ...}}&nbsp;<span translate>items</span></a>` / `<a href="" ng-click="showLocalChanged(folder.id, folder.type)">`
Quote (~:457-459): `<div ng-if="model[folder.id].ignorePatterns"><a href="" ng-click="editFolderExisting(folder, '#folder-ignores')"><i class="small" translate>Reduced by ignore patterns</i></a></div>`
Note: Fetched and read directly by me. Confirms count-as-link-to-list, and that the ignore-reduction annotation hangs off the Local State count line.

**immich-en-json**
URL: https://raw.githubusercontent.com/immich-app/immich/main/i18n/en.json
Accessed: 2026-08-19
Quote: `"asset_skipped": "Skipped"` / `"asset_skipped_in_trash": "In trash"` / `"upload_skipped_duplicates": "Skipped {count, plural, one {# duplicate asset} other {# duplicate assets}}"` / `"unsupported_file_type": "File {file} can't be uploaded because its file type {type} is not supported."` / `"backup_controller_page_remainder": "Remainder"` / `"backup_controller_page_remainder_sub": "Remaining photos and videos to back up from selection"` / `"backup_controller_page_excluded": "Excluded: "` / `"cleanup_icloud_shared_albums_excluded": "iCloud Shared Albums are excluded from the scan"`
Note: 146 KB locale file fetched and grepped directly by me. The sequential backup notification strings ("Checking for new assets…" / "Backing up your assets…" / "Asset backup complete") were reported by a delegated agent from the same file; I did not re-grep those three specific keys myself.

**bitwarden-messages-json**
URL: https://raw.githubusercontent.com/bitwarden/clients/main/apps/web/src/locales/en/messages.json
Accessed: 2026-08-19
Quote: `"importSuccess": "Data successfully imported"` / `"importSuccessNumberOfItems": "A total of $AMOUNT$ items were imported."`
Note: Retrieved by a delegated agent via raw fetch of the locale file. I did not independently re-fetch. The negative claim (no persistent import tag anywhere in the file) rests on that agent's grep, not mine.

**obsidian-importer-i18n**
URL: https://raw.githubusercontent.com/obsidianmd/obsidian-importer/master/src/i18n/en.ts and src/import-report.ts
Accessed: 2026-08-19
Quote: `msgComplete: 'Import complete.'` / `msgFinished: 'Finished {{when}}. {{counts}}.'` / `title: '{{importer}} import'` / `fileName: '{{date}} {{importer}} import log'`
Note: Retrieved by a delegated agent via raw fetch. Not independently re-verified by me.

**photoprism-en-po**
URL: https://raw.githubusercontent.com/photoprism/photoprism/develop/frontend/src/locales/en.po
Accessed: 2026-08-19
Quote: `msgid "Import completed in %d s"` / `msgid "Importing files to originals…"` / `msgid "Import canceled"` / `msgid "Import failed"`
Note: Retrieved by a delegated agent via raw fetch. Not independently re-verified by me.

**firefly-lang-php**
URL: https://raw.githubusercontent.com/firefly-iii/firefly-iii/main/resources/lang/en_US/firefly.php
Accessed: 2026-08-19
Quote: `'account_column_opt_last_activity' => 'Last activity'` / `'active' => 'Active'` / `'inactive' => 'Inactive'`
Note: Retrieved by a delegated agent via raw fetch of the 2,955-line locale file. Not independently re-verified by me. The negative claim (no import-specific account-list vocabulary) rests on that agent's grep.

**dropbox-sync-icons**
URL: https://help.dropbox.com/sync/macos-sync-icons and https://help.dropbox.com/sync/check-sync-status
Accessed: 2026-08-19
Quote: "Your file is synced and available offline" / "Your file is synced and available online" / "Your file can't update or sync" / "Your file is ignored and won't sync" / "Your files are up to date" / "Indexing" / "Syncing [file name]" / "Syncing [x] files" / "Syncing paused until [x]" / "[x] files are unable to sync"
Note: Fetched by a delegated agent. I separately fetched https://help.dropbox.com/sync/ignored-files myself and confirmed: "Ignored files are files in the Dropbox folder on your computer that aren't stored on the Dropbox server." and "The icon beside your file or folder will change to a gray minus sign, meaning it's ignored." and that the macOS feature is called "Do Not Sync". My own attempt at help.dropbox.com/sync/cant-sync-files returned HTTP 404.

**onedrive-cant-sync**
URL: https://support.microsoft.com — "fix problems" and "this file can't be synced" articles
Accessed: 2026-08-19
Quote: "OneDrive can't upload this file" / "This file is too big" / "This file can't be synced" / "This file can't be synced because OneDrive doesn't have permission to access the file" / "This file is in use by another application"
Note: Fetched by a delegated agent, which reports it directly checked the dedicated "can't be synced" article for size-cap language and found none. I did not independently re-fetch. Exact article URLs were not captured — a re-verification weak point.

**gdrive-sync-problems**
URL: https://support.google.com/drive/answer/2565956
Accessed: 2026-08-19
Quote: "Files exceed bandwidth, upload, or download limits" / "Drive for desktop will automatically retry later" / "You don't have permissions to sync files" / "Lost and Found"
Note: Fetched by a delegated agent. Not independently re-verified by me.

**1password-watchtower-fetch**
URL: https://support.1password.com/watchtower/
Accessed: 2026-08-19
Quote: "Identify vulnerable logins imported from LastPass" / "Imported from LastPass are logins that may have been compromised in a breach that LastPass experienced in August 2022." / "Find compromised websites and vulnerable passwords" / "Find websites that support passkeys" / "Locate items saved in the wrong 1Password account" / "Identify reused and weak passwords" / "Find unsecured websites" / "Identify logins that support two-factor authentication" / "Check for expiring items" / "Find duplicate items" / "Check for developer secrets on disk"
Note: Fetched directly by me. The page does NOT state what the dashboard renders when a category is empty. This partially qualifies the prior corpus entry's use of Watchtower: the headings are task-phrased imperatives on a support page, not verified dashboard chip labels.

**nc-issue-2402**
URL: https://github.com/nextcloud/desktop/issues/2402
Accessed: 2026-08-19
Quote (issue title): "Status icon in taskbar shows client fully synced while sync is actually running"
Note: Reported by a delegated agent. Title only; I did not fetch the issue body.

**nc-forum-ignored-log**
URL: https://help.nextcloud.com/t/where-to-find-a-full-log-of-ignored-files/239235
Accessed: 2026-08-19
Note: Community thread surfaced via web search, describing hover text "Sync was successful but some files were ignored" with no reachable enumeration of the ignored files in the activity list. SEARCH-SUMMARY ONLY — I did not fetch the thread body. Treat the specific UI-behaviour detail as corroborating colour, not as a verified primary fact.

**takeout-manage-exports**
URL: https://takeout.google.com (live UI auth-gated)
Accessed: 2026-08-19
Note: SEARCH-SUMMARY ONLY. The delegated agent could not fetch the live UI (login redirect, no Wayback snapshot). "Manage Exports", ~7-day expiry, and non-retention of export records are corroborated across secondary sources but NOT primary-verified. Lower confidence than everything else in this entry.

**monarch-manual-accounts**
URL: https://help.monarch.com (HTTP 403 on direct fetch)
Accessed: 2026-08-19
Note: SEARCH-SUMMARY ONLY, and the single biggest disclosed gap in this entry. The category name "Manual Accounts" and the existence of CSV balance-history upload are corroborated across secondary sources; exact on-screen list copy, badge text, and timestamp label are UNVERIFIED. A reported "Syncing 3 of 29..." progress string is likewise unverified.

## SYNTHESIS

The brief asked a narrow question — what does a consumer product call a source that is simultaneously mostly working, mid-sync, and permanently partially broken — and the honest answer is that **two of the three states have almost no prior art, and the third has exactly one good example.**

### The one real find: partiality as a peer of success, not a subtype of error

Nextcloud's desktop client is the only surveyed product that models "fine AND permanently incomplete" as a first-class state. `SyncResult::Problem` sits beside `Success` and `Error` as a named enum member, and its copy is the shape PDPP needs: **"Sync was successful but some files were ignored."** The sentence leads with the success, concedes the gap in a subordinate clause, and never uses the word error. That is a directly adoptable pattern, and it is shipped code rather than a design blog's aspiration.

Two details make it more useful than the headline string. First, Nextcloud states size-cap exclusions as **plain fact with the items listed inline and no apology**: "There are folders that were not synchronized because they are too big: " followed by the names. No "unfortunately", no "error", no retry affordance — the cause is named, the affected items are enumerated, and the sentence ends. Second, and this is the most transferable rule in the whole entry, Nextcloud **splits permanent from retryable by grammatical tense**: permanent exclusions are future declarative ("It will not be synchronized"), retryable failures are past tense with a log pointer ("could not be synced due to an error. See the log for details"). That is a rule a writer can apply mechanically, and it does the exact work PDPP's 36 oversized attachments need — they will never be collected, which is a statement about the future, not a report of a past failure.

Nextcloud also supplies the negative lesson. Its `Problem` and `Error` branches are worded almost identically — "Some files could not be synced!" vs "Some files couldn't be synced!" — separated only by a contraction, the words warnings-vs-errors, and an icon. That is a real trap: having invented a third tier, Nextcloud then wrote copy that makes it nearly indistinguishable from the second. And a community thread shows the predictable consequence of a warning whose item list isn't reachable — users see the hover text and go hunting for the log. **If PDPP adopts the tier, it must make the two strings lexically distinct and put the enumerated items one tap away**, which is precisely what Syncthing gets right and Nextcloud does not.

Syncthing supplies the missing half: a count that IS the link ("Show the number of failed items as a link to bring up the list"), and an in-place annotation for a deliberately-reduced count — "Reduced by ignore patterns", rendered as a small italic link on the count line itself, opening the reason. That annotation is the best single primitive found for PDPP's Gmail case: the total is smaller than you might expect, here is why in four words, click for detail. But Syncthing's failed-items list is explicitly the wrong model to copy wholesale, because its own copy says "They are retried automatically and will be synced when the error is resolved." Syncthing's three buckets are pending / failed / user-declared-ignore — and a size-capped item that the user never explicitly ignored lands in the ambiguous failed bucket. Nobody auto-classifies a policy-boundary item as permanently-and-normally excluded.

### Everywhere else, permanent and retryable are collapsed

Dropbox uses one tooltip ("Your file can't update or sync") for both. OneDrive puts the size case on a different help page from its can't-sync troubleshooting and gives it no distinct client treatment. Google Drive carves out exactly one retryable bucket (bandwidth, auto-retried) and dumps everything else into a "Lost and Found" folder that mixes permanent policy with transient glitch. The consistent industry default is **error-coded, undifferentiated, retry-flavoured language even when the underlying condition is permanent** — which is exactly the dishonesty PDPP is trying to avoid, and it means there is no vendor pattern to copy wholesale.

### Finished one-time imports: the pattern is that there is no pattern

This is the cleanest negative finding. Across four codebases read at source level — Bitwarden, Obsidian, PhotoPrism, Firefly III — **import completion is an EVENT, not a STATE**. A toast fires ("Data successfully imported", "Import complete.", "Import completed in %d s") and then the signal evaporates; the imported records merge indistinguishably into the general pool. Where a persistent trace exists at all, it is Obsidian's import-log Markdown note — a side artifact, not a badge on the object. Google Takeout dodges the problem structurally by making the finished thing expire. And 1Password's "Imported from LastPass", which looked like the strongest lead in the brief, turns out to be a breach-warning category, not a finished-import status — a lead that the primary source retired.

The one genuinely useful data point is Firefly III, and it is useful precisely because it declines to invent vocabulary: an account list that can hold both CSV-loaded and bridge-fed accounts uses the generic pair "Active"/"Inactive" and a column headed **"Last activity"** rather than "Last synced". That is a real, if modest, precedent for PDPP's Google Maps and WhatsApp rows: choosing a timestamp label that does not imply a future, instead of inventing an "imported" status word. Monarch Money's "Manual Accounts" is the best-named candidate for a persistent one-time category living beside live syncs, but its help centre 403'd and its exact copy is unverified — that is the single largest gap in this research and the first thing an attacking agent should probe.

**So PDPP is designing something novel here.** Not entirely — the tier exists in Nextcloud and the count-plus-drill-in exists in Syncthing — but the specific combination (auto-detected, per-item-proven, permanent, normal, and shown as an ongoing state next to a healthy source) has no product to copy. That is worth saying plainly rather than dressing up a partial match as precedent.

### Mid-sync: the fused string does not exist

Across every source-level string file read, **no product fuses last-known-good with in-flight in one sentence.** The three shipped approaches are: two separate labeled fields (Syncthing's state field plus "Last Scan"), sequential state replacement (Immich, Dropbox, Nextcloud's summary line), or an icon swap. Nextcloud actively blanks its detail line during a sync (`setSyncStatusDetailString("")`), which is the opposite of the combined string.

That is a real finding, not an absence of evidence, and it cuts against the intuition that "Last updated 2 hours ago · Syncing now" is a solved consumer pattern. It also has a documented cost: Nextcloud's icon-only approach produced a filed bug titled "Status icon in taskbar shows client fully synced while sync is actually running." Users found state-replacement ambiguous. So the prior art shows nobody has fused the two, *and* shows that not fusing them confuses people — which means PDPP's existing "Refreshing now." freshness annotation (already an enforced co-required invariant per the corpus entries) is ahead of the surveyed field, not behind it.

For the YNAB case specifically, the borrowable primitive is Nextcloud's item-count progress with an optional time clause — "Syncing %1 of %2  (%3 left)" — and the structural rule that last-good data stays fully readable throughout. No surveyed product blanks the data during a routine refresh. Nobody ships timeout/stuck copy at all; the only evidence is bug reports about its absence.

### Proposed vocabulary (actual strings)

Grounded where grounding exists, flagged where it is invention.

**State 1 — Gmail: working with a proven permanent gap.** Headline stays green; the gap is a subordinate clause, future-tense, with an enumerable count.
- Headline: `Healthy`
- Annotation line: `36 attachments are too large to collect. They will not be collected.`
- The count is the link. Affordance label: `See the 36 items`
- Detail-view heading: `Items that will not be collected`
- Per-item reason: `Larger than the 25 MB limit (48.2 MB)`
- Explicitly NOT: "error", "failed", "couldn't", "retry", "problem", "unfortunately".
- Grounding: the success-plus-clause shape and the future-declarative tense are Nextcloud's ("Sync was successful but some files were ignored"; "It will not be synchronized"); the count-as-link and the plain causal reason are Syncthing's and Nextcloud's ("There are folders that were not synchronized because they are too big: "). The pairing is mine.

**State 2 — Google Maps / WhatsApp: finished one-time import.** Avoid every word that implies a future.
- Headline: `Imported`
- Timestamp line: `Imported 12 March 2026 · 299,248 records`
- Do NOT use: "Last synced", "Last updated", "Never run", "Up to date", "Stale".
- Grounding: Firefly III's refusal to use sync-vocabulary for non-syncing accounts, and its neutral "Last activity" column, is the only real precedent. "Imported" as a status word is invention — Monarch's "Manual" is the nearest named alternative and is unverified.

**State 3 — YNAB: routine long mid-sync.** Keep last-good visible; carry freshness and activity as two elements.
- Freshness element: `Updated 47 minutes ago`
- Activity element: `Refreshing now`
- With progress where available: `Refreshing now · 1,204 of 8,000`
- Grounding: the two-element split is Syncthing's structure; the item-count progress format is Nextcloud's ("Syncing %1 of %2"). The specific fused rendering with a middot separator is invention — no product ships it.

### Where consumer framing FAILS

Three of PDPP's states have no honest consumer rendering, and a design that pretends otherwise is worse than one that admits it.

1. **"Connector code needs a fix."** The owner is not the actor and no action exists. Plaid's rule from the prior corpus entry — `display_message` is null when the error is not related to user action — says the correct owner-facing string is *nothing*. There is no consumer wording for "the software has a bug"; softening it produces a dead CTA.
2. **"Not measured" / `ProjectionReliable`.** Explaining an internal read-model rebuild to a non-technical owner is not achievable in owner-legible words. The right move is the one the corpus already identified: make the state unreachable during a run rather than find better copy for it.
3. **The 13-condition list itself.** Per the red-team entry, the surviving rule is that nobody renders the *passing* rows. Filtering is the fix; no vocabulary rescues ten green rows.

### Per-claim confidence and what would falsify it

- **Nextcloud's three-tier vocabulary and the exact strings — very high (~97%).** I fetched and read theme.cpp, syncstatussummary.cpp, and accountsettings.cpp as raw source. *Falsified by*: showing these branches are dead code, or that master has diverged from shipped releases. I did not run the client or see the UI.
- **The too-big notification is persistent, not a one-time consent modal — high (~90%).** Rests on `_ui->selectiveSyncNotification->setText(...)` in the Account Settings widget. This **corrects** a delegated agent's opposite claim. *Falsified by*: showing `selectiveSyncNotification` is hidden except during folder-add.
- **The tense rule (permanent = future declarative, retryable = past + log pointer) — medium-high (~80%).** A real pattern across the strings I read, but Nextcloud never states it as a rule. It is my generalization from ~6 string pairs. *Falsified by*: a counterexample string in the same file using past tense for a permanent exclusion.
- **Syncthing's failed-items list is explicitly retryable — very high (~97%).** Verbatim from the locale file. *Falsified by*: nothing plausible.
- **No product fuses last-known-good with in-flight — medium-high (~80%).** Strong within the four sources read at string level; it is a negative over a bounded survey. *Falsified by*: one shipped string like "Updated 2h ago · Syncing" in any product — Monarch is the likeliest place, and it is unverified.
- **Finished imports are an event not a state — high (~88%)** for Bitwarden/PhotoPrism/Obsidian/Firefly. Weakened because three of those four greps were done by a delegated agent, not by me. *Falsified by*: a persistent import-status field in any of those locale files.
- **Nobody models auto-detected permanent-and-normal partiality — medium-high (~82%).** The most important claim and a negative one. Nextcloud's `Problem` tier is genuinely close; I judge it a partial match because it bundles all "ignored" causes rather than proving permanence per item. *Falsified by*: any product showing a stable "N items permanently excluded, this is expected" state with per-item proof.
- **1Password's "Imported from LastPass" is a breach category, not an import status — high (~92%).** Fetched by me. *Falsified by*: in-app evidence it persists as a general import marker.
- **Monarch Money — low (~40%), disclosed.** 403 on every fetch. Everything about its exact copy is unverified. **Attack this first.**
- **Google Takeout "Manage Exports" — low-medium (~55%).** Auth-gated, search-summary only.
- **OneDrive / Google Drive / Dropbox strings — medium (~70%).** Delegated fetches of vendor help pages; I independently verified only Dropbox's ignored-files page. Exact article URLs for OneDrive were not captured.

**Overall:** the Nextcloud finding is strong enough to act on at >95%. The negative findings (no fused string, no permanent-partial auto-classification, imports are events) sit at 80-88% — high enough to design against, but they are negatives over a bounded survey and a single counterexample would dent any of them.
