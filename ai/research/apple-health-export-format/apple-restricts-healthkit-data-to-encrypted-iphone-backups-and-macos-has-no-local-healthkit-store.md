---
title: "Apple restricts HealthKit data to encrypted iPhone backups, and macOS has no local HealthKit store of its own"
date: 2026-09-01
topic: apple-health-export-format
tags: [apple-health, healthkit, ios-backup, macos, encrypted-backup, imazing, forensics]
status: draft
sources: [apple-support-108353, mjtsai-2016, elcomsoft-2019, elcomsoft-icloud-2018, christophhagen-healthdb, developer-forums-725411]
source_session: 477db6a2-38d5-4e08-bacb-59434740fe87
---

## CLAIMS
- macOS has no native Health app and no local HealthKit data store; Health/HealthKit data lives only on-device (iPhone/Apple Watch) at `/private/var/mobile/Library/Health/`, or inside Apple's end-to-end-encrypted iCloud — never mirrored to any `~/Library/Health`-style path on the Mac. [christophhagen-healthdb]
- An UNENCRYPTED Finder/iTunes backup of an iPhone excludes Health data entirely; only a backup with "Encrypt local backup" enabled includes the HealthKit databases (`healthdb.sqlite`, `healthdb_secure.sqlite`). [apple-support-108353]
- This exclusion was independently observed by a user in 2016: Health data vanished after restoring from an unencrypted iTunes backup, consistent with Apple's documented behavior. [mjtsai-2016]
- Forensic tooling documentation (ElcomSoft) shows the unencrypted backup has no Health section at all, versus a fully populated Activity/Heart Health section in the encrypted backup of the same device. [elcomsoft-2019]
- Pulling Health data directly from iCloud without a physical device still requires an authenticated device-equivalent flow through Apple's private APIs plus 2FA from a trusted device — not a clean, quick, self-service path. [elcomsoft-icloud-2018]
- The raw on-device/backup HealthKit SQLite schema (`samples`, `quantity_samples`, `category_samples`, `objects`, `associations` join table with blob-encoded series like HRV) is structurally unrelated to the `export.xml` format's `<Record>`/`<Workout>`/`<Correlation>` XML elements — no widely-used tool converts one into the other losslessly. [developer-forums-725411] [christophhagen-healthdb]
- `christophhagen/HealthDB` (Swift) is the most complete open-source tool for reconstructing readable Health data directly from the raw SQLite database found in an iOS backup, but it does not produce Apple's `export.xml` output format. [christophhagen-healthdb]

## SOURCES
**apple-support-108353**
URL: https://support.apple.com/en-us/108353
Accessed: 2026-09-01
Quote: "Encrypted backups can include information that unencrypted backups don't, such as your Health data (on devices with iOS 4 or later, and iPadOS)."

**mjtsai-2016**
URL: https://mjtsai.com/blog/2016/01/12/unencrypted-itunes-backups-dont-include-health-data/
Accessed: 2026-09-01
Quote: "Unencrypted iTunes backups don't include Health data."

**elcomsoft-2019**
URL: https://blog.elcomsoft.com/2019/01/securing-and-extracting-health-data-apple-health-vs-google-fit/
Accessed: 2026-09-01
Quote: "the unencrypted backup contains no Health information whatsoever, while the encrypted backup of the same device includes full Activity and Heart Health data"

**elcomsoft-icloud-2018**
URL: https://blog.elcomsoft.com/2018/11/extracting-apple-health-data-from-icloud/
Accessed: 2026-09-01
Quote: "extraction requires authentication with the Apple ID and password, plus a second factor from one of the user's trusted devices"

**christophhagen-healthdb**
URL: https://github.com/christophhagen/HealthDB
Accessed: 2026-09-01
Quote: "This project can be used to reconstruct Health data from the SQLite database contained in an iOS backup."

**developer-forums-725411**
URL: https://developer.apple.com/forums/thread/725411
Accessed: 2026-09-01
Quote: "quantity samples and category samples are joined to their parent objects row, and correlated samples use the associations table"

## SYNTHESIS
Two facts compound to make "get my real Apple Health data onto a phone-less Mac" much harder than it looks: (1) macOS genuinely has zero local HealthKit storage — there is no filesystem path worth searching on the Mac itself — and (2) Apple deliberately gates Health data behind encrypted-backup status, so even an existing Finder backup on the Mac is only useful if it happened to be encrypted at creation time. The only zero-phone path to real personal data is an old encrypted backup already sitting in `~/Library/Application Support/MobileSync/Backup/`, decryptable with tools like iMazing using the backup's own password (not the Apple ID password). Even then, the payload is raw SQLite, not `export.xml` — anything consuming Apple's XML export format needs a real conversion step that no mainstream open-source tool currently provides losslessly. This generalizes beyond one demo: any tooling built against "Apple Health data" needs to decide up front whether it accepts `export.xml` (requires a live iOS device export) or raw HealthKit SQLite (requires an encrypted backup + custom parsing), because the two are not interchangeable without bespoke conversion work.
