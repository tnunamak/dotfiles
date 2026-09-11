---
title: LibreChat hands-free voice needs four per-browser settings, and librechat.yaml alone cannot set them
date: 2026-09-11
source_session: 07c5dfa0-d041-44e2-bc19-bb9561fe30ff
tags: [librechat, stt, tts, voice, self-hosted, configuration]
---

## Problem

"Advanced voice mode" in LibreChat (toggle mic, speak, get spoken reply, keep
talking) is not a single switch. It is four independent settings, and editing
`librechat.yaml` does not reliably change them for an existing user.

## The four settings

| setting | what it does | hands-free value |
|---|---|---|
| `autoTranscribeAudio` | transcribe while the mic is open instead of only on stop | `true` |
| `autoSendText` | seconds of silence before auto-submitting; `0` = never, `-1` = disabled | `2` (or `3`) |
| `automaticPlayback` | speak the reply without clicking the speaker | `true` |
| `conversationMode` | reopen the mic after the reply | `true` |

`decibelValue` (default `-45`) is the voice-activity threshold that decides when
speech has stopped, so it gates whether `autoSendText` ever fires. If auto-send
does not trigger, this is the value to tune, not `autoSendText`.

## The trap: yaml sets DEFAULTS, localStorage wins

`speech.speechTab` in `librechat.yaml` only seeds **initial** values. Once a user
has opened Settings → Speech, their per-browser `localStorage` values override
the server config. A server-side edit then appears to do nothing.

Verify what the server is actually serving:

    GET /api/files/speech/config/get     (bearer token from POST /api/auth/refresh)

If that returns the intended values but behaviour is unchanged, the saved
browser prefs are the cause. Keys are stored bare in `localStorage`
(`autoTranscribeAudio`, `autoSendText`, `automaticPlayback`, `conversationMode`,
`engineSTT`, `engineTTS`, `languageSTT`, `voice`).

Upstream tracks a related bug where the yaml override direction is reversed:
danny-avila/LibreChat#6168 — speechTab config overriding user settings.

## Two adjacent gotchas found the same day

**`languageSTT` must be an ISO-639-1 code.** LibreChat validates against
`/^[a-z]{2}(-[a-z]{2})?$/`. A display name like `"English (US)"` fails, logs
`[STT] Invalid language format`, and the language hint is silently dropped. Use
`"en-US"`. This value also lives in localStorage, so fixing the yaml is not
enough.

**Private-IP STT/TTS endpoints need an SSRF exemption.** LibreChat refuses to
call LAN addresses:

    SSRF protection: 192.168.1.180 resolved to blocked address 192.168.1.180

The fix is `allowedAddresses: ["host:port"]`, and it must sit at the **section**
level (`speech.stt`, `speech.tts`), NOT under the provider block beneath it —
`STTService.js` reads `sttSchema.allowedAddresses`. Nested under `stt.openai` it
parses fine and is never read, so the failure looks identical.

That failure surfaces in the UI as the misleading red banner *"An error occurred
while processing the audio, maybe the audio was too short"*, which is simply
LibreChat's generic STT exception message. The audio length is irrelevant.

## Debugging note

The STT error handler logs a bare message with no stack. Temporarily replacing
the log line with one that prints `error.message` and the first stack frames is
what turned an unfalsifiable "audio too short" into a one-line diagnosis. The
API can be driven headlessly: `POST /api/auth/refresh` for a JWT, then
`POST /api/files/speech/stt` (multipart, field `audio`) and
`POST /api/files/speech/tts/manual` (multipart, fields `input`/`voice`).
`POST /api/files/speech/tts` is a different route that expects a messageId.

## Sources

- https://www.librechat.ai/docs/configuration/stt_tts
- https://www.librechat.ai/docs/configuration/librechat_yaml/object_structure/speech
- https://github.com/danny-avila/LibreChat/issues/6168
- https://github.com/danny-avila/LibreChat/issues/4807
