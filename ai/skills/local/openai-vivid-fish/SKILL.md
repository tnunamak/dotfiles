---
name: ai-gateway-vivid-fish
description: Use Vivid Fish AI Gateway (the local OpenAI-compatible AI gateway, formerly openai-proxy/openai.vivid.fish) for chat, embeddings, image generation/editing, TTS, STT, audio generation, video jobs, model/voice listing, gateway-native capabilities/receipts, Anthropic Messages, Ollama-compatible chat/generate, and Telegram media replies. Triggers on "Vivid Fish AI Gateway", "AI Gateway", "ai.vivid.fish", "openai.vivid.fish", "vivid fish", local LLM/TTS/STT, image gen/edit, audio/video generation, gateway discovery, receipts, voice notes, Telegram audio, or helpers in ~/applications/daisy/scripts.
---

# Vivid Fish AI Gateway

`https://ai.vivid.fish/v1` is the canonical public base URL for the self-hosted AI gateway, served externally via Traefik (192.168.1.4 -> host:5000). The older `https://openai.vivid.fish/v1` host remains a compatibility alias for existing OpenAI-shaped app configs. The gateway is implemented by `~/applications/openai-proxy/proxy.py` and routes to local backends:

- **TabbyAPI** (Qwen3-VL) — chat/completions/vision (port 5050)
- **GGUF backend** — koboldcpp or llama-turbo on port 5051 (mutually exclusive via systemd `Conflicts=`; swap with `llm-switch {kobold|turbo|tabby}`)
- **Voxtral-4B (vLLM)** — TTS (port 8001)
- **Parakeet TDT 0.6B** — STT (port 5092)
- **ComfyUI** — image generation + edit (port 7890), default image model `flux2-klein-4b`; video via LTX-2.3 22B (`ltx-2.3` / `ltx-2.3-distilled`, dev Q4_K_M GGUF + distilled-LoRA, audio-video joint output)

When working inside the daisy project, prefer the project helpers in `~/applications/daisy/scripts/`. For other agents/contexts, hit the HTTP API directly with curl using the examples below.

Use unauthenticated discovery before assuming a backend:

```bash
curl -fsS "$BASE/health"
curl -fsS "$BASE/.well-known/ai-gateway" || curl -fsS "$BASE/.well-known/openai-proxy"
```

## Auth

- Runtime App API key env var: `AI_GATEWAY_API_KEY` or legacy `VIVID_OPENAI_API_KEY` / `OPENAI_PROXY_API_KEY` (Daisy reads from `~/applications/daisy/.env`).
- Base URL env var: `AI_GATEWAY_BASE_URL` or legacy `VIVID_OPENAI_BASE_URL`; prefer `https://ai.vivid.fish/v1` for new setup.
- Pass App keys as `Authorization: Bearer $AI_GATEWAY_API_KEY` (or the legacy env var already in use). App keys start with `opk_`.
- Admin/control-plane keys start with `oak_` and are only for `/admin/api/*`; never put an `oak_...` key into an OpenAI-compatible app.
- If the env var is missing, source the relevant project `.env` or fail loudly with the missing-key message — do **not** print the key value or guess.

## Endpoint surface

| Method + Path | Backend | Purpose | Typical timing |
|---|---|---|---|
| `GET /health` | proxy | Liveness; public, no auth | <100ms |
| `GET /.well-known/ai-gateway` | proxy | Public gateway metadata and discovery links | <100ms |
| `GET /admin` | proxy | Admin dashboard; requires `oak_...` bearer key or signed OIDC session | <100ms |
| `GET /admin/login` | proxy | OIDC browser login when configured; returns 501 until OIDC config exists | <100ms |
| `POST /admin/api/apps`, `POST /admin/api/apps/{id}/keys` | proxy | Admin control plane for registering Apps and minting one-time `opk_...` App keys | <100ms |
| `GET /v1/models` | active LLM backend + proxy catalog | List configured roles, optional aliases, and currently loaded GGUF | <1s |
| `GET /v1/voices`, `GET /v1/audio/voices` | proxy (static) | List TTS voices | <100ms |
| `POST /v1/chat/completions` | tabby (default) or kobold (auto-routed by `model`) | Chat completion (vision-capable on tabby) | varies |
| `POST /v1/completions` | tabby/kobold | Text completion | varies |
| `POST /v1/responses` | translates to chat/completions | OpenAI Responses API (spring 2025). Stateful conversations via `previous_response_id`, function tools, `text.format` (json_object/json_schema), streaming SSE. Hosted tools NOT supported. | varies |
| `GET /v1/responses/{id}` | proxy SQLite (`data/responses.db`) | Retrieve a stored response | <100ms |
| `DELETE /v1/responses/{id}` | proxy SQLite | Delete a stored response | <100ms |
| `POST /v1/embeddings` | tabby | Embeddings | <2s |
| `POST /v1/audio/speech` | Voxtral TTS | OpenAI-compatible TTS, voice-mapped | ~2-10s |
| `POST /v1/audio/transcriptions` | Parakeet STT | Multipart audio → transcript | ~1-5s |
| `POST /v1/images/generations` | ComfyUI | Text-to-image (`flux2-klein-4b`) | ~30s |
| `POST /gateway/v1/media/jobs` | proxy + ComfyUI | Durable async media jobs; for images send `{"intent":"image.generate","request":{...}}` | <1s submit |
| `GET /gateway/v1/media/jobs/{id}`, `GET /gateway/v1/media/jobs/{id}/content` | proxy | Poll/fetch durable image job outputs | <500ms |
| `POST /v1/images/edits` | ComfyUI | Image edit; multipart with input image | ~2min |
| `POST /v1/videos` | ComfyUI | Submit video job (Sora-shaped, async) | <1s submit |
| `GET /v1/videos/{id}` | ComfyUI | Poll job status (`queued` -> `running` -> `succeeded`/`failed`) | <500ms |
| `GET /v1/videos/{id}/content` | ComfyUI | Fetch rendered MP4 once `status=succeeded` | <2s |
| `GET /v1/images/{id}/content` | proxy (cache) | Fetch a cached image referenced by a `response_format: "url"` result. Auth-gated; URL is HMAC-signed with a TTL. | <100ms |
| `* /<any other>` | tabby | Catch-all proxy to TabbyAPI (admin/model load endpoints, etc.). If tabby is unavailable, the proxy returns 503 with `Retry-After` rather than silently routing to kobold (which has a different surface). | varies |

Public routes are `/health` and `/.well-known/*`. Runtime routes (`/v1`, `/api`, `/gateway/v1`) require an App bearer token. Admin routes (`/admin`, `/admin/api/*`) require an admin bearer token or a signed OIDC dashboard session. App keys cannot administer the gateway.

### Chat completions

```bash
curl -s https://ai.vivid.fish/v1/chat/completions \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "messages": [{"role":"user","content":"hi"}],
    "max_tokens": 256
  }'
```

- `model: "default"` works as a logical role alias (configured in `proxy_config.yml`). Use the actual model id (e.g. `qwen3-vl-30b`) for explicit routing.
- Vision routing (real behavior):
  - The proxy scans every chat completions request for `image_url` / `input_image` content blocks before routing.
  - If the active backend is vision-capable (kobold with `--mmproj` loaded, or tabby with a VL EXL3), the request stays put and the response carries `X-Vision-Routed: true`.
  - If the active backend is text-only and `roles.vision` is configured, the proxy auto-switches to that role's backend (cold-start + load if needed).
  - If neither is true, the request is **rejected with HTTP 400** (`code: vision_unsupported`) — image content is never silently dropped.
  - Every chat-completions response carries `X-Vision-Routed: true | false | not-needed` for observability.
- **Timeouts.** The proxy's upstream read timeout is **per-chunk idle** (not wall-clock). Default 600s — covers slow prompt processing on reasoning/vision models (Qwen3.6 27B PP on 4K-token vision prompt ≈ 150s). Long structured outputs at >5 tok/s never approach it. Tunable via `model_routing.upstream_read_timeout` in `proxy_config.yml` or `UPSTREAM_READ_TIMEOUT` env. **Use `stream: true` to dodge timeouts entirely on very long completions** — proper SSE pass-through, X-Vision-Routed header preserved.
- **`reasoning_effort` (OpenAI-compatible).** Accepts `none`, `minimal`, `low`, `medium`, `high`, `xhigh`. Behavior on local reasoning models (Qwen3.6 family — binary thinking switch):
  - `none` / `minimal` → suppresses thinking (injects `/no_think` + `chat_template_kwargs.enable_thinking=false`). Response has empty `reasoning_content`, `content` carries the answer.
  - `low` / `medium` / `high` / `xhigh` → no-op; model thinks normally.
  - Invalid values → HTTP 400 with `{"error": {"type": "invalid_request_error", "param": "reasoning_effort", ...}}`.
  Same translation applies to `/v1/responses` via `reasoning.effort` (nested under `reasoning`, per OpenAI spec).

### Responses API (`/v1/responses`)

The newer (spring 2025) OpenAI surface. Modern SDKs (`@ai-sdk/openai` v6+ in particular) default to it. The proxy implements it as a translation layer over `/v1/chat/completions`, so every routing decision (model resolution, backend selection, vision detection) flows through the same code path as chat completions.

```bash
curl -s https://ai.vivid.fish/v1/responses \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "input": "Say hi in 3 words.",
    "max_output_tokens": 128,
    "reasoning": {"effort": "minimal"}
  }'
```

**Stateful conversations.** When `store: true` (default), each response is persisted to `~/applications/openai-proxy/data/responses.db` (SQLite, 7-day retention, hourly pruner). A follow-up call with `previous_response_id` walks the stored chain and reconstructs the message history transparently:

```bash
# Second turn references first by id; the proxy reconstructs context server-side
curl -s https://ai.vivid.fish/v1/responses \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"default","previous_response_id":"resp_…","input":"What did I just ask?","reasoning":{"effort":"minimal"}}'
```

Send `"store": false` to skip persistence (no `previous_response_id` chaining possible from that turn).

**Streaming.** Set `"stream": true` to receive SSE events in the canonical Responses shape: `response.created`, `response.in_progress`, `response.output_item.added`, `response.content_part.added`, `response.output_text.delta`, `response.output_text.done`, `response.content_part.done`, `response.output_item.done`, `response.completed`. Tool-call streaming emits `response.function_call_arguments.delta` / `.done`.

**Reasoning effort mapping (best-effort).** `reasoning.effort: "minimal"` is translated to `chat_template_kwargs.enable_thinking: false` (recognized by llama-server's Qwen3 chat template) plus a `/no_think` system-prompt suffix as fallback. `low`/`medium`/`high` pass through unchanged — the local backend has no first-party reasoning-budget knob. Reasoning emitted by the model is surfaced as a `reasoning` output item (with `content[].type == "reasoning_text"`) preceding the assistant `message` item.

**Response format.** `text.format.type == "json_object"` -> Chat Completions `response_format: {type: "json_object"}`. `text.format.type == "json_schema"` -> `response_format: {type: "json_schema", json_schema: {name, schema, strict}}`. Both are honored by llama-server when grammar/JSON enforcement is enabled.

**Function tools.** `tools: [{type: "function", name, description, parameters, strict}]` translates cleanly to Chat Completions `tools[].function`. The model receives the schema; when it decides to call, the response includes a `function_call` output item (`{type: "function_call", call_id, name, arguments}`). The client is expected to execute the tool and chain back via `previous_response_id` + a `function_call_output` input item.

**Hosted tools NOT supported.** `web_search`, `web_search_preview`, `file_search`, `code_interpreter`, `computer_use`, `image_generation` (as a tool), `mcp`, `shell`, `apply_patch` all return **HTTP 400** with `code: hosted_tool_not_supported`. These require OpenAI's first-party infrastructure (the local backend has no equivalent). For image generation, use the dedicated `/v1/images/generations` endpoint; for web search, run the search externally and inject results as `input` text.

**Server-side tool loop NOT implemented.** When the model emits a `function_call`, the response ends and the client must execute the tool itself, then chain a new request. (The "agent in a loop" pattern is out of scope for v1.)

**Retrieve / delete.** `GET /v1/responses/{id}` returns the stored response body verbatim. `DELETE /v1/responses/{id}` removes it (returns `{id, object: "response.deleted", deleted: true}`).

### Models list

```bash
curl -s https://ai.vivid.fish/v1/models \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY"
```

Returns a unified catalog:

1. **Roles** (from `proxy_config.yml` `roles:` block) — entries like `default`, `vision`, `rp`, `coder`. Marked with `"vivid_fish_role": true`. Send `"model": "<role>"` and the proxy resolves the role to its backend + GGUF and cold-swaps via `ensure_target()` on first use (~30-60s; transparent thereafter).
2. **Catalog aliases** (from `proxy_config.yml` `models:` block) — friendly names for arbitrary GGUFs (e.g. `heretic-v2`, `cydonia-24b`). Marked with `"vivid_fish_alias": true`. Same swap semantics as roles; use when you want to expose a GGUF without inventing a workflow-shaped role.
3. **Active backend's own catalog** — Tabby's list when tabby is hot, kobold's loaded-model metadata when kobold is hot.
4. **Currently-loaded GGUF** — filename-only entry marked `"vivid_fish_loaded": true` so clients can see what's actually hot without parsing a path.

Each role/alias entry carries advisory `vivid_fish_*` extension fields: `vivid_fish_backend` (`kobold` | `tabby`), `vivid_fish_model_path` (absolute GGUF path — informational only; never send this as `model:` in requests). Use the short `id` instead.

Useful for sanity-checking what's hot before sending a large request, and for populating model-picker UIs (LibreChat etc.) with everything the proxy can serve, not just the one GGUF currently in VRAM.

### Image generation (text-to-image)

Default model: `flux2-klein-4b`. Recommended texture model:
`flux2-klein-4b-seamless-tile`; direct SDXL postprocess model:
`sdxl-seamless-tile`.
Response: `data[].b64_json` (base64 PNG) or `data[].url` (signed URL)
depending on `response_format`.

```bash
curl -s -m 120 -X POST https://ai.vivid.fish/v1/images/generations \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"flux2-klein-4b","prompt":"a tabby cat under neon","n":1,"size":"1024x1024","response_format":"b64_json"}' \
  -o /tmp/result.json

python3 -c "import json,base64;d=json.load(open('/tmp/result.json'));open('/tmp/out.png','wb').write(base64.b64decode(d['data'][0]['b64_json']))"
```

`n` (1-10) is honored: the proxy adaptively batches into ComfyUI rounds based on free VRAM, returning all `n` distinct images. If even a single image won't fit in free VRAM, the response is HTTP 503 with `Retry-After: 30` — the proxy never silently truncates.

For unattended batches or clients that cannot keep a long HTTP request open,
prefer the durable job surface:

```bash
curl -s -X POST https://ai.vivid.fish/gateway/v1/media/jobs \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: image-batch-001" \
  -d '{"intent":"image.generate","request":{"model":"flux2-klein-4b","prompt":"a tabby cat under neon","n":1,"size":"1024x1024"}}'
```

Poll `GET /gateway/v1/media/jobs/{job_id}` and fetch
`GET /gateway/v1/media/jobs/{job_id}/content` when `status` is `succeeded`.
Durable image jobs always return signed URL-backed assets, not base64 blobs.

`response_format: "url"` returns hostname-aware, HMAC-signed URLs that resolve to `GET /v1/images/{id}/content`. URLs are valid for ~1 hour (configurable via `images.signed_url_ttl` in `proxy_config.yml`) and require the same bearer token as everything else. Cached image bytes evict after 24 h (`images.cache_ttl`). Every image result also includes gateway-native `asset_id`, `asset_url`, and `media_type`; use `asset_id` for later gateway-aware calls made by the same API key and `asset_url` for signed `/v1/assets/{asset_id}/content` fetches.

For game texture tiles, prefer `model: "flux2-klein-4b-seamless-tile"` and put
workflow knobs under `extensions.com.vividfish.workflow`. It is gateway
composed: Flux2 txt2img, 50%/50% circular offset, seam-cross mask, Flux2
inpaint repair, then offset back. Useful controls are base `steps`, `guidance`,
`seed`, plus `seam_mask_width`, `seam_mask_feather`, `seam_denoise`,
`seam_steps`, `seam_guidance`, and optional `seam_prompt`.

```bash
curl -s -m 180 -X POST https://ai.vivid.fish/v1/images/generations \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "flux2-klein-4b-seamless-tile",
    "prompt": "hand-painted underwater basalt floor texture, game asset, tileable",
    "size": "1024x1024",
    "n": 1,
    "response_format": "b64_json",
    "extensions": {
      "com.vividfish.workflow": {
        "steps": 5,
        "guidance": 3.5,
        "seed": 4242,
        "seam_mask_width": 96,
        "seam_mask_feather": 32,
        "seam_denoise": 0.58,
        "seam_steps": 8
      }
    }
  }' \
  -o /tmp/tile.json
```

`sdxl-seamless-tile` remains available as a direct SDXL workflow with
postprocessing. Its controls are `steps`, `guidance`, `seed`,
`negative_prompt`, `sampler`, `scheduler`, and `seam_blending`; `seam_blending`
must be in `0..0.5`. It is not the full circular SDXL stack.

Response headers exposed for observability:
- `X-Image-Rounds`: how many ComfyUI submissions backed this request.
- `X-Image-Returned`: how many images are in `data[]`.
- `X-Image-Seamless-Tile-Strategy` (tile route): currently `offset-inpaint`.
- `X-Proxy-Warning` (when present): non-fatal warnings (e.g. partial result).

Chaining: video `input_reference` accepts prior image handles as `{"asset_id":"img_<sha256>"}` or `asset:img_<sha256>` when the same API key minted the asset. Asset-valued workflow controls such as future `control_image` can also use `{"asset_id":"img_<sha256>"}` when discovery shows the selected workflow supports that input. For image variants, use top-level `n`; for repeatability, use manifest-backed `extensions.com.vividfish.workflow.seed` only when discovery lists `seed`. For video variants, repeat calls with different top-level `seed`.

Prompting tips: specificity beats description. Use `ONLY`, `exactly`, `do not change X`. Vague prompts cause complete regeneration.

### Image edit (multipart)

Edits an existing image. Requires both `image` and `prompt`. Model defaults to `flux2-klein-4b-edit`; if you pass `flux2-klein-4b` the proxy auto-appends `-edit`. Size is auto-detected from the image when omitted.

```bash
curl -s -m 240 -X POST https://ai.vivid.fish/v1/images/edits \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -F "model=flux2-klein-4b-edit" \
  -F "prompt=replace the sky with aurora; do not change the foreground" \
  -F "image=@/path/to/input.png;type=image/png" \
  -F "n=1" \
  -F "response_format=b64_json" \
  -o /tmp/edit.json

python3 -c "import json,base64;d=json.load(open('/tmp/edit.json'));open('/tmp/edit.png','wb').write(base64.b64decode(d['data'][0]['b64_json']))"
```

Multipart fields:

- `image` (required, file): PNG/JPEG. Sent through to ComfyUI.
- `prompt` (required, string).
- `mask` (optional, file): standard OpenAI image-edit field. Keep it top-level, not inside `extensions`. Transparent alpha pixels are edited and opaque pixels are preserved; grayscale white edits and black preserves. Masked `flux2-klein-4b-edit` requests auto-select `flux2-klein-4b-inpaint` when available; that workflow applies the normalized mask inside ComfyUI. If no native mask workflow exists for a model, the gateway falls back to post-composite preservation.
- `model` (optional): defaults to `flux2-klein-4b-edit`; non-`-edit` names get the suffix appended.
- `size` (optional): e.g. `1024x1024`. Auto from input if omitted.
- `n` (optional, int, default 1, 1-10). Honored via adaptive ComfyUI batching. 503 with `Retry-After` if VRAM cannot fit even one image.
- `response_format` (optional): `b64_json` (default) or `url`. Both are fully supported; `url` returns signed URLs that hit `GET /v1/images/{id}/content`.
- `extensions` (optional, JSON object string): gateway-native workflow controls go under `extensions.com.vividfish.workflow`, e.g. `-F 'extensions={"com.vividfish.workflow":{"denoise":0.42,"steps":24,"guidance":3.5}}'`. For `flux2-klein-4b-inpaint`, discovery also shows `mask_expand` and `mask_feather`. Do not send `denoise`, `controlnet_strength`, sampler knobs, etc. as top-level OpenAI fields.

ControlNet/conditioning controls are only usable when discovery shows a real workflow manifest that exposes them. For multipart image edits, an asset-valued workflow control can reference an extra form field without making that field a public OpenAI parameter:

```bash
curl -s -m 240 -X POST https://ai.vivid.fish/v1/images/edits \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -F "model=flux2-klein-4b-edit-controlnet" \
  -F "prompt=preserve the geometry, paint it as underwater rock" \
  -F "image=@/path/to/input.png;type=image/png" \
  -F "control_image=@/path/to/edge-map.png;type=image/png" \
  -F 'extensions={"com.vividfish.workflow":{"control_image":{"multipart_field":"control_image"},"controlnet_strength":0.75}}'
```

Fetch `/gateway/v1/workflows` or `/gateway/v1/extensions` first. If `control_image` or `controlnet_strength` is absent for the selected workflow, treat the capability as unavailable rather than trying to force it.

Top-level OpenAI image fields stay top-level (`image`, `mask`, `prompt`, `model`, `size`, etc.). Gateway controls stay under `extensions.com.vividfish.workflow`. Unknown top-level fields are rejected with HTTP 400 `code: "unknown_parameter"`; invalid/unsupported extension input is rejected with HTTP 400 `code: "invalid_extension"`; workflow extensions on a workflow with no extension support are rejected with "workflow extensions are not supported for the resolved image workflow". The proxy should never silently drop mask/inpaint or denoise intent.

Timing: ~2 min per call (per image-gen ref). Set generous client timeouts.

Errors return JSON `{ "error": { "message": ..., "type": ..., "param": ..., "code": ... } }` with status 400/502/503.

### Audio generation

`POST /v1/audio/generate` is a gateway-native ComfyUI audio/music route. It returns audio bytes directly.

ACE-Step music workflows accept top-level `tags` and `lyrics`:

```bash
curl -s -m 600 -X POST https://ai.vivid.fish/v1/audio/generate \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ace-step-1.5-xl-turbo",
    "tags": "dream pop, warm piano, soft drums",
    "lyrics": "first line of the song\nsecond line of the song",
    "duration": 20,
    "seed": 1234
  }' \
  -o /tmp/music.wav
```

For ACE-Step, `prompt` remains accepted and maps to the workflow's `tags` input when `tags` is absent. If both are present, `tags` wins. TangoFlux uses `prompt` for SFX/ambient descriptions; top-level `lyrics` is ignored unless the selected workflow declares a lyrics binding. Workflow controls stay under `extensions.com.vividfish.workflow`; keep `duration`, `seed`, `tags`, and `lyrics` top-level. ACE-Step exposes `bpm`, `cfg`, `cfg_scale`, `denoise`, `keyscale`, `language`, `min_p`, `sampler`, `scheduler`, `steps`, `temperature`, `timesignature`, `top_k`, and `top_p`. TangoFlux exposes `steps`, `guidance`, and `batch_size`. Fetch `/gateway/v1/extensions` for the live list.

For lyric clarity, especially rap, keep `tags` and `lyrics` distinct:
`tags` should describe genre, instruments, tempo, and vocal treatment; `lyrics`
should include structure tags such as `[verse]`, `[chorus]`, or
`[verse - rap]`. Avoid cramming four lyric lines into a 5-second clip. Use
8-12 seconds for short intelligibility samples and 20+ seconds for a verse,
with short lines and clean-vocal tags such as `dry clear male rap vocal`,
`clean enunciation`, `moderate tempo`, `no mumble rap`, and `no heavy vocal
effects`. If working inside Daisy, use the `music-video` skill's
`generate-audio-samples-via-vivid` helper and local STT transcription before
claiming a vocal sample is clear.

### Video generation

Sora-2-shaped async API for local LTX-Video 2.3 generation via ComfyUI. Three endpoints work as a submit-poll-fetch flow. **Output mp4s and PNG images embed the full UI-format workflow in metadata, so dragging an output file into ComfyUI's web frontend rebuilds the editable graph (drag-drop loads nodes/links/groups).**

**Endpoints:**

| Path | Purpose |
|---|---|
| `POST /v1/videos` | Submit; returns `{id, status: "queued"}` quickly |
| `GET  /v1/videos/{id}` | Poll status; transitions `queued` → `running` → `succeeded` / `failed` |
| `GET  /v1/videos/{id}/content` | Download MP4 (Content-Type `video/mp4`); only valid when `status=succeeded` |

**Request body (POST /v1/videos):**

```json
{
  "model": "ltx-2.3",
  "prompt": "A red fox walking through a snowy forest at dusk, cinematic",
  "size": "1280x720",
  "seconds": 5,
  "seed": 42,
  "negative_prompt": "low quality, blurry"
}
```

- `model` (required-ish, defaults to `ltx-2.3`):
  - `ltx-2.3` (aliases: `ltx-2.3-distilled`, `ltx-2.3-22b`) — LTX-2.3 22B (dev Q4_K_M GGUF) + distilled-LoRA two-stage T2V/AV. Generates synchronised video + audio. Range: 1-8 s. Wall time on a 3090: ~5-10 min for 720p / 5 s (first-call cold load is slower; the 22B class on a 24 GB card relies on ComfyUI's `--lowvram` block-swap and is ~1.5-2× the fp8-resident reference).
  - `ltx-2.3-distilled-fast` (aliases: `ltx-2.3-fast`, `ltx-2.3-pure-distilled`) — LTX-2.3 22B pure-distilled standalone GGUF (single-stage, no LoRA, no upsampler). 8 steps, CFG=1, full resolution. Same audio+video output as the hybrid. Wall time on a 3090: ~70 s warm for 3 s / 720p (measured 2026-05-05, consistent across back-to-back runs); ~3-4 min on a fully cold first call when the model still has to load. Quality trade-off: less fine detail than the hybrid on complex scenes, but plenty for previews and iteration.
  - `ltx-2.3-detail` — LTX-2.3 hybrid + LTX-2 19B IC-LoRA Detailer for sharper textures (skin, fabric, foliage). Same wall time as `ltx-2.3`. Best LTX quality + audio.
  - `ltx-2.3-long` (alias: `ltx-2.3-long-form`) — LTX-2.3 22B distilled GGUF in a chunked single-pass for-loop (RuneXX architecture). Each iteration adds a 10 s window with 2 s overlap; the proxy derives the loop count from `seconds`. Range: 1-50 s. Audio + video (model-generated, same chain as the short distilled aliases — `LTXVAudioVAEDecode`). Wall time on a 3090 (measured 2026-05-07): **~4:41 warm for 30 s / 768x416** (281 s), **~15:01 warm for 30 s / 1280x720** (901 s). Peak GPU0 VRAM at 1280x720: ~17.3 GB resident with --lowvram block-swap (~13.9 GB further offloaded to system RAM). Camera-control LoRA disabled by default. Notes: longer videos amplify motion drift across chunk boundaries (a known LTX/RuneXX architecture trade-off, not a bug). Use this for >8 s clips; for short clips prefer the single-pass aliases above.
  - `wan-2.2` (alias: `wan-2.2-ti2v-5b`) — Wan 2.2 TI2V-5B Q8 GGUF (QuantStack/Wan2.2-TI2V-5B-GGUF). Photoreal output, **NO audio**. Single-stage 20-step uni_pc CFG=5 with `ModelSamplingSD3` shift=8. Range: 1-5 s. Wall time on a 3090: ~3-6 min for 3 s / 720p.
  - `sora-2`, `sora-2-pro` — OpenAI Sora aliases; auto-resolve to `ltx-2.3` for SDK compatibility.

**Model selection cheat sheet**

| Goal | Model | Wall time (3 s / 720p, 3090) | Audio | I2V |
|---|---|---|---|---|
| Speed (preview/iteration) | `ltx-2.3-distilled-fast` | ~70 s warm / ~3-4 min cold | yes | yes (LTX inplace, strength knob) |
| LTX with audio + reasonable quality (default) | `ltx-2.3-distilled` | ~5 min | yes | yes (LTX inplace, strength knob) |
| LTX best quality + audio | `ltx-2.3-detail` | ~5 min | yes | yes (LTX inplace, strength knob) |
| Long-form (>8 s, up to 50 s) | `ltx-2.3-long` | 30 s @ 768x416: ~4:41 warm; 30 s @ 1280x720: ~15:01 warm | yes (model-generated) | yes (anchors first chunk's frame 0) |
| Photoreal, no audio | `wan-2.2` | ~3-6 min | no | yes (native `Wan22ImageToVideoLatent.start_image`; no strength knob) |

Every video alias accepts `input_reference` for I2V. Pass an absolute path, https URL, data URI, or prior image `asset_id` minted by the same API key. Omit it for T2V. See the I2V example below.

**Per-model prompting notes**

- LTX-2.3 (any variant): see the LTX-2.3 prompting notes elsewhere in this skill — Lightricks' canonical "core actions / visual details / audio" framing applies; specificity beats density.
- Wan 2.2 5B: prompts in either English or Chinese work (the model was co-trained). Photoreal scene descriptions land best when they describe camera language ("slow dolly", "tracking shot") and lighting; abstract or surreal prompts produce muddier output than LTX. No audio cues — anything sound-related in the prompt is ignored.
- `prompt` (required, string).
- `size` (optional, default `1280x720`). Capped at `1280x720` per workflow. Width/height auto-rounded to multiples of 32.
- `seconds` (optional, default 5). Range per alias: 1-8 for `ltx-2.3`/`ltx-2.3-distilled-fast`/`ltx-2.3-detail`, 1-50 for `ltx-2.3-long`, fixed 3 for `wan-2.2` (out-of-range → 400). The proxy honors the requested duration exactly. For LTX, output durations land at `(seconds × 24 + 1) / 24` due to the 8N+1 LTX latent-stride frame count (e.g. requested 3 → 3.04 s, requested 8 → 8.04 s); this ~0.04 s codec rounding is inherent to the model and does not surface a header. If a request requires rounding outside that natural stride for any other reason, the response carries `X-Duration-Adjusted: requested=<r> actual=<a> reason=<reason>` so callers can react. For `ltx-2.3-long`, the proxy solves `(LENGTH, LOOPS)` against the RuneXX duration formula to hit any target ≥ 1 s — short requests use `LOOPS=0` with `LENGTH=seconds`; longer requests fix `LENGTH=10` and tune `LOOPS` to land on the target.
- `seed` (optional int). Omitted -> random.
- `negative_prompt` (optional string). Falls back to a sensible default in the workflow.
- `input_reference` (optional): I2V reference image. Accepts an absolute file path, an `https://` URL, a `data:image/...;base64,...` URI, a raw base64 string, `{"asset_id":"img_<sha256>"}`, or `asset:img_<sha256>` from the same API key. When set, the workflow runs in I2V mode: frame 0 of the output is anchored to the reference image; subsequent frames are denoised by the prompt. Every video alias supports I2V via the same workflow (one workflow per alias handles both T2V and I2V). LTX aliases use `LTXVImgToVideoInplaceKJ` at strength 1.0 (T2V passthrough = strength 0.0); Wan 2.2 wires `start_image` into `Wan22ImageToVideoLatent` natively. The reference image is auto-resized by the model to the requested `size` (no client-side resize required).
- `image_strength` (optional float, 0.0-1.0, default 1.0). Only meaningful for LTX aliases when `input_reference` is set. 1.0 pins frame 0 hard to the reference; lower values let the sampler drift further from the reference. Wan 2.2 has no strength knob — passing this value is a no-op on `wan-2.2`.

**Response shape (POST):**

```json
{
  "id": "video_<comfy_prompt_id>",
  "object": "video.generation",
  "model": "video-ltx-2.3-distilled",
  "status": "queued",
  "progress": 0,
  "created_at": 1746556800,
  "expires_at": 1746643200,
  "size": "1280x704",
  "seconds": 5
}
```

**Poll response (GET /v1/videos/{id}):**

```json
{
  "id": "video_<id>",
  "object": "video.generation",
  "status": "running",
  "progress": 47,
  "step": 12,
  "total": 25,
  "node": "84",
  "phase": "sampling"
}
```

Progress is now real: the proxy subscribes to ComfyUI's websocket and tracks the live sampler step. `progress` is a 0-100 estimate that combines a phase heuristic (encoding 0-5%, sampling 5-90%, decoding 90-99%, terminal 100) with the sampler's `step/total`. `step`, `total`, `node`, and `phase` are present during the run. Polling every 3-5s gives smooth updates; the websocket pushes events live so even faster polls won't stall. If the websocket can't reach ComfyUI, the proxy falls back to history polling and you'll see only the coarser `status`/`progress` fields.

Once `status=succeeded`, fetch the MP4 from `/content`. On `status=failed`, the response includes an `error` field with the ComfyUI execution error (truncated to 500 chars).

**I2V usage example** (anchor frame 0 to a reference image, then animate from the prompt):

```bash
curl -s -X POST https://ai.vivid.fish/v1/videos \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ltx-2.3",
    "prompt": "the koi swims slowly across the pond, water ripples expand outward",
    "seconds": "5",
    "size": "768x432",
    "input_reference": "/path/to/reference.png"
  }'
```

`input_reference` also accepts `https://` URLs, `data:image/png;base64,...` URIs, and prior image asset handles from the same API key (`{"asset_id":"img_<sha256>"}` or `asset:img_<sha256>`). The proxy uploads the image to ComfyUI's input cache, sets the workflow's LoadImage node to the uploaded filename, and (on LTX) flips `image_strength` to `1.0`. Omit `input_reference` to run T2V — the strength knob stays at `0.0` so the placeholder image is a passthrough no-op.

**Full submit-poll-fetch curl example:**

```bash
# 1. Submit
SUBMIT=$(curl -s -X POST https://ai.vivid.fish/v1/videos \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"ltx-2.3-distilled","prompt":"A goldfish swimming in clear water","seconds":3,"size":"1280x720"}')

VIDEO_ID=$(echo "$SUBMIT" | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
echo "video_id: $VIDEO_ID"

# 2. Poll until terminal status
while :; do
  POLL=$(curl -s -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
    "https://ai.vivid.fish/v1/videos/$VIDEO_ID")
  STATUS=$(echo "$POLL" | python3 -c 'import json,sys;print(json.load(sys.stdin)["status"])')
  echo "status: $STATUS"
  case "$STATUS" in
    succeeded|failed|canceled) break ;;
  esac
  sleep 5
done

# 3. Fetch the mp4
[ "$STATUS" = "succeeded" ] && curl -s -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  "https://ai.vivid.fish/v1/videos/$VIDEO_ID/content" -o /tmp/out.mp4 && file /tmp/out.mp4
```

**Timing expectations (RTX 3090, 720p / 3-5 s):**

| Model | Wall time | Audio | Notes |
|---|---|---|---|
| `ltx-2.3` (22B dev Q4_K_M + distilled-LoRA, two-stage AV) | ~5-10 min | yes | Quality + audio in one pass. First call cold load adds ~30-60 s. |
| `ltx-2.3-distilled-fast` (22B pure-distilled GGUF, single stage) | ~70 s warm / ~3-4 min cold | yes | 8 steps CFG=1; preview/iteration speed. Measured 2026-05-05. |
| `ltx-2.3-detail` (hybrid + IC-LoRA Detailer) | ~5-10 min | yes | Sharper textures, same wall time as `ltx-2.3`. |
| `wan-2.2` (TI2V-5B Q8 GGUF) | ~3-6 min | no | Photoreal; uni_pc 20-step CFG=5 + ModelSamplingSD3 shift=8. |

The 22B-class models with `--lowvram` block-swap on a 24 GB 3090 are the working-memory ceiling we accept (Tim's GPU0 budget allows ~8-10 GB working VRAM next to image-gen). FP8 has no Ampere acceleration, so Q4_K_M / Q8 GGUF quants are the right choice on this card.

**Block-swap caveat — ComfyUI queue serializes.** A running video job will pause `/v1/images/generations`, `/v1/images/edits`, and any other ComfyUI traffic for the whole job. Image gen and TTS clients should expect added latency or simply be queued behind the video. TTS (Voxtral) and STT (Parakeet) live on separate processes and are unaffected by ComfyUI activity. Set client timeouts to ≥ 30 min on `/v1/videos/{id}` polling loops; a single submit returns in <1 s but the underlying job can run for several minutes.

**Determinism note.** With a fixed `seed`, output is byte-identical across calls only when sampler, scheduler, and node graph stay byte-identical. Don't promise reproducibility across model upgrades.

**License.** This is a personal-use deployment — license filtering is not enforced. LTX-Video 2.3 is OpenRAIL-M (Lightricks), Wan 2.2 is Apache-2.0.

### Sending video to Telegram

After generating a video via `/v1/videos`, deliver the mp4 to Telegram with the daisy helper:

```bash
/home/tnunamak/applications/daisy/scripts/send-telegram-video-via-vivid /path/to/video.mp4

# with caption
send-telegram-video-via-vivid --caption "Your goldfish, sir" /path/to/video.mp4

# preview without sending
send-telegram-video-via-vivid --dry-run /path/to/video.mp4
```

The script handles auth (`TELEGRAM_BOT_TOKEN` from `.env`, chat id from `.pi/agent/telegram.json`'s `allowedUserId`).

Caveats:

- Telegram's Bot API caps video uploads at **50 MB**. Most LTX-2.3 outputs at 720p / 3-8 s land under 5 MB, so this rarely matters; the helper fails fast with a clear error if the file is over the limit.
- mp4 (h264 + AAC) is the supported format; LTX outputs are already in this format. Other containers (webm, mkv) get rejected by Telegram with the error surfaced verbatim.
- `supports_streaming=true` is set automatically so Telegram pre-loads the file for instant playback.

### Telegram video request flow (full recipe)

When Tim asks for a video over Telegram, run the submit-poll-fetch-send sequence end to end:

```bash
# 1. Submit job
SUBMIT=$(curl -fsS -X POST "$AI_GATEWAY_BASE_URL/videos" \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"ltx-2.3-distilled","prompt":"<one-paragraph shooting-script prompt>","seconds":3,"size":"1280x720"}')
ID=$(echo "$SUBMIT" | jq -r .id)

# 2. Poll every 5-10s until terminal status
while :; do
  POLL=$(curl -fsS -H "Authorization: Bearer $AI_GATEWAY_API_KEY" "$AI_GATEWAY_BASE_URL/videos/$ID")
  STATUS=$(echo "$POLL" | jq -r .status)
  case "$STATUS" in succeeded|failed|canceled) break ;; esac
  sleep 5
done
[ "$STATUS" = "succeeded" ] || { echo "$POLL" >&2; exit 1; }

# 3. Fetch mp4
OUT=/tmp/daisy-video-${ID}.mp4
curl -fsS -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  "$AI_GATEWAY_BASE_URL/videos/$ID/content" -o "$OUT"

# 4. Send to Telegram
/home/tnunamak/applications/daisy/scripts/send-telegram-video-via-vivid \
  --caption "Your goldfish, sir" "$OUT"

# 5. Optional cleanup at end of session
# rm /tmp/daisy-video-*.mp4
```

Inside a Telegram turn, call `send-telegram-video-via-vivid` directly to deliver the file. The `<!-- telegram_voice: ... -->` marker convention only applies to TTS audio, and `telegram_attach` would deliver the mp4 as `sendDocument` (no inline preview / streaming) instead of `sendVideo`.

### How to prompt for good LTX-2.3 video

LTX-2.3 rewards a single, present-tense paragraph from a shooting script — not a tag list, not a one-liner, not a novel. It conditions on a Gemma-3 encoder and follows camera language, lighting, and beat structure literally. Lazy prompts produce slow-motion artifacts, soft faces, and drifting motion.

**Length and structure.** 4-8 sentences in one flowing paragraph; roughly one paragraph per 3-5 s of video. Order: (1) shot type and setting, (2) subject with concrete physical detail, (3) action as a beat sequence, (4) camera move and where it ends, (5) lighting and mood, (6) audio. Use present-tense verbs ("walks", "tilts", "exhales").

**Cinema vocabulary, used correctly.** `close-up`, `medium shot`, `wide shot`, `over-the-shoulder`, `dolly in/out`, `pan left/right`, `tilt up/down`, `tracking shot`, `handheld`, `static frame`, `jib up/down`, `push in`, `pull back`, `slow motion`, `lingering shot`. A `pan` rotates in place — it cannot "pan away from" a subject; that's a `cut` or `tilt`. A `tracking shot` moves with the subject; a `dolly in` moves toward it. Describe where the subject ends up *after* the move ("the camera dollies back, revealing her long white dress") so the model can complete the motion.

**Match complexity to length.** Short prompt + long video → slow-motion drift and frozen poses. Novel-length prompt + short clip → truncated/compressed output. Rule: 3-5 sentences per 3-5 s, 5-8 per 8-10 s.

**Resolution.** Locally cap is 1280x720 (24 GB 3090 with `--lowvram`). 1080p needs 32 GB+ VRAM officially and OOMs on this host. Drop to 960x544 only when iterating fast.

**What LTX-2.3 does well.** Slow-to-medium camera moves; atmospheric lighting (golden hour, neon, fog, rim light, candlelight); single-subject emotional close-ups with subtle gestures and facial nuance; stylized aesthetics (noir, painterly, fashion editorial, period drama); multiple subjects in *calm* scenes; photorealistic skin and fabric textures (especially with the Detail LoRA).

**What LTX-2.3 does poorly** (per Lightricks devs). Fast acrobatic movement, jumping, twisting, parkour, fighting; complex physics; readable text and logos; overloaded scenes with many actors doing different actions; conflicting lighting sources. Dancing is OK; chaotic motion is not.

**Concrete bad → good rewrites:**

- *Bad:* `Faceshot of young woman in windy forest.`
  *Good:* `A cinematic medium close-up of a young woman standing in a windy autumn forest at golden hour. Loose strands of her dark hair lift across her cheek as she looks slightly off-camera, lips parted, eyes soft. The camera dollies back slowly, revealing her long white linen dress brushing the tall grass. Warm side-light filters through pine trunks behind her, catching dust motes. A soft wind hisses through the leaves; distant birdsong; no dialogue.`

- *Bad:* `Goldfish swimming.`
  *Good:* `A cinematic underwater shot of a single ornate goldfish drifting through a sunlit freshwater tank. The camera tracks alongside it from left to right at a steady, lazy pace, holding a shallow focus on the fish while plants blur in the background. Shafts of light cut down through the surface and ripple across the gravel below. Ambient bubbling water and a faint low hum; no music.`

- *Bad:* `Chef cooking, fast cuts.`
  *Good:* `An over-the-shoulder medium shot of a middle-aged chef in a navy apron working at a stainless steel pass. He plates a single seared scallop with tweezers, then drizzles brown butter from a small steel spoon. The camera holds static for the first two seconds, then pushes in slowly on the plate as steam rises. Warm overhead key light, cool kitchen reflections in the steel. The clatter of distant pans, sizzle of fat, no dialogue.`

**Audio prompting.** LTX-2.3 generates synchronized audio jointly with video. Describe the soundscape in the same paragraph: "soft wind, distant church bell"; "low cello drone under sparse piano"; "no dialogue" if you don't want voice. The local Q4_K_M GGUF audio is roughly half the quality of the full-precision dev model — expect light hiss; lean on ambient/music over dialogue when fidelity matters.

**Dialogue / spoken lines (load-bearing).** LTX-2.3 detects dialog only when the line is wrapped in **double quotes**. Without quotes the model produces vague mouth movement and ambient sound; with quotes it produces lip-synced speech. Always specify the speaker, the line, and the emotion/voice — and language/accent if non-English. Recipes:

- *Bad:* `the man yells back off monkey repeatedly in an upset voice` → produces ambient grunts, no intelligible speech.
- *Good:* `The man shouts "Back off, monkey!" repeatedly in an upset, frustrated voice (English).`
- Multi-line: `She whispers "stay with me", then cries out "no, no!"`
- Non-English: `She whispers in French, "reste avec moi" (soft, intimate tone).`

If you forget the quotes, the audio chain still runs — but the result will be wordless. Re-render with quoted lines.

**I2V composition tips.** When you pass an `input_reference`, the proxy auto-derives the output `size` from the reference image's aspect ratio (unless you override `size`). This avoids center-cropping your subject. If you do override `size`, the workflow uses letterbox padding (`keep_proportion=pad`) instead of cropping — preserves the whole subject with black bars. Either way, the input image's framing is preserved; do not pre-crop it client-side.

**Negative prompts.** Default: `blurry, low quality, still frame, frames, watermark, overlay, titles, has blurbox, has subtitles`. Add per-shot via `negative_prompt`. Useful: `soft focus, plastic skin, washed out, low detail` (faces); `frozen pose, slow motion, ghosting` (motion); `text, captions, logo` (signs/screens).

**Model selection (which alias).**

| alias | when |
|---|---|
| `ltx-2.3-distilled` (default) | Drafts, prompt iteration. ~5-10 min on a 3090. |
| `ltx-2.3` | Reserved for future hybrid quality path; today same as distilled. |
| `ltx-2.3-detail` | Any shot where fine textures matter — skin, fabric, hair, leaves, wood, jewelry, food. Chains the IC-LoRA Detailer model-only on the distilled chain. Same wall time. |

**Avoid:** internal emotional labels ("she is sad" — show, don't tell), in-frame text/logos, more than 2-3 actors doing different actions, conflicting light logic, multi-step physics ("the ball bounces three times then rolls" — pick one beat).

### Text-to-speech

```bash
curl -s -X POST https://ai.vivid.fish/v1/audio/speech \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"tts-1","input":"Hello world.","voice":"nova","response_format":"opus","speed":1.0}' \
  -o /tmp/out.opus
```

Body is forwarded to Voxtral after voice mapping. Unknown voices fall back to `neutral_female`.

### Speech-to-text

```bash
curl -s -X POST https://ai.vivid.fish/v1/audio/transcriptions \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
  -F "file=@/path/to/audio.ogg" \
  -F "model=whisper-1" \
  -F "response_format=json"
```

Returns `{"text": "..."}`. The proxy forwards multipart untouched to Parakeet.

### Voices list

```bash
curl -s https://ai.vivid.fish/v1/voices \
  -H "Authorization: Bearer $AI_GATEWAY_API_KEY"
```

The listing is the authoritative set of voices the speech endpoint accepts. Each entry includes `voice_id`, `name`, `language`, `gender`, `description`, and `mapped_to` (the underlying Voxtral voice). All `it_*`, `nl_*`, `pt_*`, `ar_*`, `hi_*` voices appear here.

### Health

```bash
curl -s https://ai.vivid.fish/health
```

Returns `{status, auth_enabled, proxy_keys_configured}`. No auth required.

## Voice mapping (OpenAI → Voxtral)

The proxy maps OpenAI voice names to Voxtral voices in the request body. Unknown voices → `neutral_female`.

| OpenAI voice | Voxtral voice |
|---|---|
| alloy | neutral_female |
| echo | casual_male |
| fable | cheerful_female |
| nova | casual_female |
| onyx | neutral_male |
| shimmer | cheerful_female |
| sophia / sage | neutral_female |
| isabella / ballad | cheerful_female |
| lily / coral / juniper | casual_female |
| evan / ash | casual_male |
| adam | neutral_male |
| verse | neutral_male |

Voxtral native voices pass through unchanged: `casual_female`, `casual_male`, `cheerful_female`, `neutral_female`, `neutral_male`, plus `{lang}_{gender}` for `ar, de, es, fr, hi, it, nl, pt`.

## Daisy helper scripts (`~/applications/daisy/scripts/`)

Prefer these over raw curl when running inside the daisy project — they handle auth, audio normalization, and output paths automatically.

| Script | Purpose | When to use |
|---|---|---|
| `generate-image-via-vivid "<prompt>"` | Calls `/v1/images/generations`, decodes b64, prints output PNG path. | Telegram "generate an image" / any image-gen request. |
| `transcribe-via-vivid <audio>` | Normalizes audio, calls `/v1/audio/transcriptions`, prints transcript text only. | When inbound voice/audio needs transcription. (Telegram already runs this.) |
| `speak-via-vivid "<text>"` | Calls `/v1/audio/speech`, prints generated audio file path. | Producing a TTS file for non-Telegram use. |
| `send-telegram-voice-via-vivid "<text>"` | TTS + sends as a Telegram voice note via the paired bot. | "say it", "reply by voice", "talk back". |
| `send-telegram-video-via-vivid [--caption TEXT] <video.mp4>` | Sends an mp4 to Telegram via `sendVideo`. Auto-resolves chat id from `telegram.json`. | After fetching `/v1/videos/{id}/content` to deliver the rendered clip. |
| `send-telegram-approval-prompt` | Approval-prompt helper (unrelated to media). | Approval flows. |
| `check-service-prereqs` | Sanity-check daisy prereqs. | Diagnosing daisy startup. |

No helper exists yet for `/v1/images/edits` — use the curl recipe above.

## Telegram-specific behavior

- When a Telegram prompt includes an `[outputs]` block following a voice/audio attachment, that block already contains the transcript. Do **not** re-transcribe — use it as the user's message unless empty or obviously wrong.
- **Voice-or-text per reply is the model's choice.** To send a voice note, embed an HTML comment marker anywhere in the reply: `<!-- telegram_voice: "the spoken text" -->`. The Daisy extension extracts that text and TTS-sends it via `send-telegram-voice-via-vivid`. The visible text reply is also delivered to Telegram.
  - Heuristics (not rules): user sent a voice note → voice usually fits; user sent text → text is the default but voice is fine when it makes sense ("say it", "tell me out loud", emotional/casual moments). Long technical or code content → text only.
  - Omit the marker entirely when no voice note is wanted.
  - Do not call `send-telegram-voice-via-vivid` directly during a Telegram turn — emit the marker and let the extension run it. (Direct calls are still appropriate from non-Telegram contexts.)
- For "generate an image" requests in Telegram, run `generate-image-via-vivid`, then call `telegram_attach` with the printed image path before the final reply.

## Rules

- **Never print** `AI_GATEWAY_API_KEY`, `TELEGRAM_BOT_TOKEN`, or any other secret in output, logs, or error messages.
- Prefer daisy helpers over raw curl when on daisy; otherwise use the curl recipes here.
- Generated artifacts live under `~/applications/daisy/tmp/` unless the user specifies a path. For non-daisy contexts use `/tmp/` or the user-specified path.
- If a helper or curl call fails, report the concise error + the helper/endpoint name. Do not retry blindly — check `GET /health` and `GET /v1/models` first.
- Image edits take ~2 minutes; set client timeouts ≥ 240s.
- LLM requests can stall if the wrong backend is hot. If `/v1/models` shows the wrong model, ask the user before invoking `llm-switch` (it restarts a systemd service).

## References

- Proxy source: `~/applications/openai-proxy/proxy.py`
- Proxy config: `~/applications/openai-proxy/proxy_config.yml`
- Image gen notes: `~/.claude/refs/image-gen.md`
- LLM proxy stack overview: `~/.claude/refs/llm-proxy.md`
