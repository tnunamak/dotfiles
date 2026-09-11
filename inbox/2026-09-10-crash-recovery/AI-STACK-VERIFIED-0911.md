# AI stack — every surface verified working, 2026-09-11

All probes run with **each client's own API key**, not an admin key, so the
results reflect what that client can actually do.

| surface | LibreChat | Open WebUI |
|---|---|---|
| `GET /v1/models` | 200 | 200 |
| `POST /v1/chat/completions` | 200 | 200 |
| `POST /v1/embeddings` | 200 | 200 |
| `POST /v1/responses` | 200 | — |
| `POST /v1/images/generations` | 200 | 200 |
| `POST /v1/images/edits` | 200 | 200 |
| `POST /v1/audio/speech` (TTS) | 200 | 200 |
| `POST /v1/audio/transcriptions` (STT) | 200 | 200 |
| `POST /v1/videos` | 200 | 200 |

LibreChat additionally verified through its OWN authenticated endpoints in a
real browser (not just server-side probes): chat renders "gateway ok" on the
page, `/api/files/speech/stt` returns a transcript, `/api/files/speech/tts/manual`
returns 176 KB of `audio/mpeg`, and an image edit attached a new 413 KB render
routed through `flux2-klein-4b-edit`.

## What was actually broken, and why each looked like something else

**Profile grants.** Both frontends were stuck with hand-enumerated protocol
lists from a May legacy import (`openai.chat`, `openai.completions`,
`openai.embeddings` only). Model listing 403'd, and images/audio/video/responses
were all blocked. The gateway prefix-matches (`gateway/policy.py:262`), so the
fix is a family grant: `openai` covers every `openai.*`. `Legacy librechat` also
got `anthropic`. `Legacy cap` still has only `openai.audio` — left alone, that
is plausibly correct for a screen recorder.

**Video was never broken.** `POST /v1/videos {"model":"default"}` returned
"Unknown video model/workflow", which read as unconfigured. Five workflows,
their ComfyUI graphs and ~33 GB of LTX/WAN weights were present and generating
the whole time. `VIDEO_DEFAULT_WORKFLOW` only applies when `model` is OMITTED,
not when it is the literal `"default"` — which is what works for chat and
images. Registered `default` as an alias; all three surfaces now agree.

**LibreChat's "audio was too short" banner was an SSRF block.** LibreChat
refuses to call private IPs. Every voice request died before leaving the
container with `SSRF protection: 192.168.1.180 resolved to blocked address`,
which is why the gateway logs showed nothing arriving. The banner is just its
generic STT exception text; audio length was irrelevant. Fix is
`allowedAddresses: ["192.168.1.180:5000"]` at the **section** level
(`speech.stt`, `speech.tts`) — nested under the provider it parses and is never
read, because `STTService.js:181` reads `sttSchema.allowedAddresses`.

**LibreChat title generation was failing on every conversation.** `titleModel`
was `gpt-4o-mini`, a model this gateway does not serve, so every title request
400'd. Now `default-fast`.

**Open WebUI had four misconfigurations**, none of which would surface as an
obvious error: image generation pointed at `llm.vivid.fish` (wrong host) with a
5-character placeholder key; image edit was disabled and pointed at real
`api.openai.com`; STT and TTS were both unset (falling back to local Whisper /
disabled) and pointed at real OpenAI with no key. All four now point at the
gateway with its real key.

**Empty transcripts were falsy.** Silence returns `{"text": ""}`, which is
correct and matches OpenAI, but a client doing `!response.data.text` treats it
as failure. The gateway now returns a single space for exactly that case.

## Backups

- `openai-proxy/proxy.py.bak-20260911-stt`, `proxy_config.yml.bak-20260911-video`
  (both changes also committed: `8b021b8`)
- `librechat.yaml.bak-20260911`, `.bak2-`, `.bak3-` on `root@192.168.1.4`
- `open-webui`: `/app/backend/data/webui.db.bak-20260911` inside the container

## Known remaining

- **Hands-free voice** in LibreChat: the four settings (`autoTranscribeAudio`,
  `autoSendText`, `automaticPlayback`, `conversationMode`) are correct in both
  the yaml and the test browser, and `languageSTT` is now the valid `en-US`.
  If auto-send still does not fire, `decibelValue` (-45) is the voice-activity
  threshold that decides when speech has stopped — that is the value to tune.
  See `ai/research/self-hosted-ai/librechat-hands-free-voice-*.md`.
- **Open WebUI RAG embeddings** still use the local
  `sentence-transformers/all-MiniLM-L6-v2` rather than the gateway's
  `nomic-embed-text-v1.5`. Deliberate default, not a fault.
