---
title: "NVIDIA's own support documentation recommends deleting the GLCache (OpenGL shader) and ComputeCache (CUDA JIT) caches as a standard troubleshooting step, so both are safe for automated disk cleanup — but should be gated on size, not file age, because eviction is size-driven and cache-hit mtime-update behavior is undocumented"
date: 2026-08-29
topic: dev-tool-caches
tags: [nvidia, cuda, gpu, shader-cache, glcache, computecache, disk-cleanup]
status: draft
sources: [nvidia-kb-5735, nvidia-forums-ahuillet, nvidia-cuda-programming-guide, empirical-repro]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CLAIMS

- On this machine (two real NVIDIA RTX 3090 GPUs, confirmed via `lspci`), the only subdirectory that exists under `~/.cache/nvidia` is `GLCache` (248M) — the CUDA JIT kernel cache is NOT co-located there; it lives separately at `~/.nv/ComputeCache` (66M, confirmed present on this machine). A cleanup category targeting "the NVIDIA cache" needs to cover both paths, not just `~/.cache/nvidia`. [empirical-repro]
- NVIDIA's own support knowledge base explicitly recommends deleting the shader cache as a troubleshooting step for crashes, visual artifacts, and performance regressions, and states it will regenerate automatically: "Once you have removed the NVIDIA cache, the files will then be automatically regenerated over time." Corruption is presented as a reason TO delete the cache, not a risk of deleting it. [nvidia-kb-5735]
- An NVIDIA developer-forums response (from an NVIDIA staff account) states directly: "Should be safe to cleanup. Users should be ok with this data getting cleaned up between sessions." [nvidia-forums-ahuillet]
- The GLCache has a documented soft size cap (~128MB) enforced by NVIDIA's own garbage collection, which normally runs at application startup — per an NVIDIA engineer's forum response: "The shader cache size is a (soft) maximum of 128MB." An observed real-world size well above this cap (248M on this machine) indicates the auto-eviction either hasn't run recently (no eligible app launch to trigger it) or per-directory accounting differs from the aggregate; either way it does not indicate anything unsafe about deleting the excess. [nvidia-forums-ahuillet]
- The CUDA JIT cache (`~/.nv/ComputeCache` by default) is controlled by `CUDA_CACHE_PATH` (location) and `CUDA_CACHE_MAXSIZE` (default 1 GiB on desktop, 256 MiB on embedded platforms) per NVIDIA's own CUDA Programming Guide appendix on environment variables — it is also self-managed by size, not age. [nvidia-cuda-programming-guide]
- No official NVIDIA documentation describes cache-hit behavior updating file mtimes (vs. only cache-write behavior) — this is an unconfirmed gap, meaning an "old mtime = unused" heuristic for THIS specific cache type is not verified and should not be relied upon as a staleness signal, unlike (for contrast) the `python_venvs`/`node_modules` categories in this codebase, which use project-source mtime specifically because that recency signal IS meaningful for those artifact types.

## SOURCES

**nvidia-kb-5735**
URL: https://nvidia.custhelp.com/app/answers/detail/a_id/5735/
Accessed: 2026-08-29
Quote: "If the NVIDIA Shader Cache files are damaged, it may cause applications or games to crash on launch, exhibit lower performance, or display visual artifacts... Once you have removed the NVIDIA cache, the files will then be automatically regenerated over time."

**nvidia-forums-ahuillet**
URL: https://forums.developer.nvidia.com/t/opengl-shader-disk-cache-max-size-garbage-collection/60056
Accessed: 2026-08-29
Quote: "The shader cache size is a (soft) maximum of 128MB."

**nvidia-cuda-programming-guide**
URL: https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/environment-variables.html
Accessed: 2026-08-29
Quote: "CUDA_CACHE_MAXSIZE ... specifies the size of the compute cache in bytes; the default size is 1 GiB, and the size can be increased if needed. Caches that need more space than allowed will evict the oldest binaries first to make room."

**empirical-repro**
URL: n/a (local verification, this machine)
Accessed: 2026-08-29
Quote: "du -sh ~/.cache/nvidia/* → 248M GLCache (only subdirectory present)" / "du -sh ~/.nv → 66M" (separate ComputeCache location confirmed to exist independently)

## SYNTHESIS

Unlike `mise` (previous entry, same session) where the right move is full delegation to a built-in command, NVIDIA provides no equivalent "prune my shader cache" CLI tool — the sanctioned mechanism is literal directory deletion (`rm -rf` the cache dir or its contents), which the support KB itself describes as the fix. This makes it a legitimate `probe_du_path`-style category (mirroring existing categories like `pip_cache`/`npm_cache` in this codebase, which are also just "measure the dir, offer to `rm -rf` it wholesale" rather than surgically pruning specific files).

The correct design: treat as tier-1 (like other pure caches), gate on a size threshold (the CUDA programming guide's own 1GiB default cap is a reasonable reference point for what NVIDIA itself considers "large enough to matter"), and explicitly do NOT use a recency/mtime gate the way `node_modules`/`python_venvs` do — those use mtime because a project going stale is a meaningful, well-understood signal; there is no equivalent documented understanding of what NVIDIA cache mtimes mean, and inferring "old mtime = unused" here is an unverified assumption per NVIDIA's own docs. Cover both real paths found on this machine: `~/.cache/nvidia` (GLCache, and any sibling dirs NVIDIA may add) and `~/.nv/ComputeCache` (a separate, undocumented-by-cache-name-convention location that would be silently missed by a check that only looks under `~/.cache`).
