---
title: "Electron's safeStorage on Linux (Chromium os_crypt) has no migration path between keyring backends, and its KWallet/libsecret key derivation is a fixed, reproducible PBKDF2+AES-128-CBC scheme"
date: 2026-08-29
topic: desktop-app-secrets
tags: [electron, chromium, os_crypt, kwallet, libsecret, safestorage, sqlcipher, linux]
status: draft
sources: [chromium-source-key-storage-linux, chromium-source-os-crypt-linux, signal-desktop-issue-7944, sigtop-repo]
source_session: ff819ac4-f054-4918-9c2d-edddd4da0b14
---

## CLAIMS

- Chromium's Linux `os_crypt` derives its AES-128-CBC encryption key via PBKDF2-HMAC-SHA1 with a **hardcoded salt `"saltysalt"`, exactly 1 iteration, and a fixed 16-space-character IV** — the same formula regardless of which keyring backend supplied the password. [chromium-source-os-crypt-linux]
- The PBKDF2 "password" input is not the final key — it is a random 16-byte value, base64-encoded, generated once and stored **as that base64 text string itself** (not decoded back to raw bytes) in the OS keyring backend (KWallet or libsecret). The ciphertext is prefixed with `v10` (hardcoded fallback password `"peanuts"`) or `v11` (real keyring-backed password) so a decrypt implementation can detect which recipe applies. [chromium-source-os-crypt-linux]
- Chromium/Electron's **KWallet-native** backend (`KeyStorageKWallet`) stores its password under a KWallet **folder+entry pair** named after the app's product name (e.g. `"Chrome Keys"` / `"Chrome Safe Storage"`), reachable only via KWallet's own D-Bus API (`org.kde.KWallet`), not the generic Secret Service (`org.freedesktop.secrets`) API. [chromium-source-key-storage-linux]
- Chromium/Electron's **libsecret** backend (`KeyStorageLibsecret`) stores the same kind of password under a *different* mechanism entirely: a Secret Service item with schema `chrome_libsecret_os_crypt_password_v2` and a single `application` attribute (e.g. `application=Signal`), labeled `"<AppName> Safe Storage"` (e.g. `"Chromium Safe Storage"`). This is retrievable via generic tools like `secret-tool search --all application <name>`, unlike the KWallet-folder path. [chromium-source-key-storage-linux]
- These two backends are **not the same secret and are not interchangeable** — an app's password stored via one mechanism will not be found by code that only knows how to query the other, even on the same running KWallet/Secret-Service daemon.
- Signal-Desktop's own open GitHub issue #7944 confirms: **there is no general migration logic** when Electron's `safeStorage` backend changes (e.g. `kwallet5→kwallet6`, or `gnome_libsecret→basic_text`) — the app just throws `SafeStorageBackendChangeError` / fails outright, rather than re-deriving or re-encrypting the stored key under the new backend. Only a narrow `kwallet5↔kwallet6` special case is handled; `gnome_libsecret↔basic_text`, `kwallet*↔basic_text`, and `gnome_libsecret↔kwallet*` transitions are all unhandled as of this writing. Flatpak builds default to the weak `basic_text` (plaintext) backend specifically as a workaround for this same class of bug. [signal-desktop-issue-7944]
- `sigtop` (github.com/tbvdm/sigtop, ISC-licensed Go CLI) independently reimplements this entire pipeline (KWallet + libsecret backends, SQLCipher decryption) to read Signal Desktop's local database without Electron at all. Its `-k [system:]keyfile` flag accepts a raw/derived key directly, bypassing keyring lookup — useful for testing candidate keys against a SQLCipher-encrypted `db.sqlite` copy without needing to write anything into the live keyring. [sigtop-repo]

## SOURCES

**chromium-source-os-crypt-linux**
URL: https://chromium.googlesource.com/chromium/src/+/3f85aea3bf92db168ea7d3f8a286d77651d751b1/components/os_crypt/sync/os_crypt_linux.cc
Accessed: 2026-08-29
Quote: "constexpr char kSalt[] = \"saltysalt\";" / "constexpr size_t kEncryptionIterations = 1;" / "const std::string iv(kIVBlockSizeAES128, ' ');" / "// V11 will not be used if such a library is not available."

**chromium-source-key-storage-linux**
URL: https://chromium.googlesource.com/chromium/src/+/3f85aea3bf92db168ea7d3f8a286d77651d751b1/components/os_crypt/sync/key_storage_kwallet.cc and .../key_storage_libsecret.cc
Accessed: 2026-08-29
Quote: "base::Base64Encode(base::RandBytesAsString(16), &password);" (both backends generate the password identically, but store it via completely different APIs/schemas)

**signal-desktop-issue-7944**
URL: https://github.com/signalapp/Signal-Desktop/issues/7944
Accessed: 2026-08-29
Quote: "No general migration logic exists beyond a single kwallet5 ↔ kwallet6 pathway" / "Flatpak defaults to basic_text (plaintext storage) as a compatibility workaround, exposing the broader issue"

**sigtop-repo**
URL: https://github.com/tbvdm/sigtop
Accessed: 2026-08-29
Quote: "[-BD] [-d signal-directory] [-k [system:]keyfile] [file]" (usage string, extracted from binary strings)

## SYNTHESIS

The practical trap: an app can appear to work fine across a keyring/DE migration (e.g. KDE
Plasma 5→6, kwalletd5→kwalletd6) for days or weeks, then silently break the moment its
`safeStorage`-encrypted key needs re-derivation, because Chromium/Electron never
implemented a recovery/migration path for most backend transitions — only Signal's narrow
kwallet5↔6 case is special-cased at all, and even that is fragile. The correct diagnostic
order when this happens: (1) confirm which keyring backend the app's config file records
(e.g. `safeStorageBackend` field) vs what's actually running now; (2) separately check BOTH
the KWallet-folder path AND the libsecret Secret-Service path for a matching password,
since an app may have silently regenerated a *new* password under one mechanism while an
old, no-longer-matching password still sits under the other; (3) treat any password/secret
you find as unverified until you actually successfully decrypt something with it — do not
assume a secret is "the" key just because its name/schema looks plausible. A tool like
`sigtop`'s `-k` flag (or an equivalent "supply raw key directly" mode) is the fastest way to
test candidate keys against a real encrypted database without risking any writes to the
live keyring or app data.
