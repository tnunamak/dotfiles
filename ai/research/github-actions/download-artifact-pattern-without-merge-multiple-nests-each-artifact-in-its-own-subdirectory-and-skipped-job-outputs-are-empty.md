---
title: "download-artifact with `pattern` and default `merge-multiple: false` nests each artifact in a subdirectory named after the artifact, a skipped/failed job's `needs.*.outputs` is an empty object (so outputs read as empty string), and buildx `imagetools` needs no builder while `--format '{{json .Manifest.Digest}}'` emits a quoted digest with NO trailing newline"
date: 2026-08-17
topic: github-actions
tags: [github-actions, docker-buildx, release-pipeline, artifacts, multi-arch, digest, needs-context]
status: verified
sources:
  - https://github.com/actions/download-artifact
  - https://github.com/actions/upload-artifact
  - https://docs.github.com/en/actions/reference/workflows-and-actions/contexts
  - https://docs.docker.com/reference/cli/docker/buildx/imagetools/create/
source_session: 8ecf9187-e87a-417a-9a90-1b1c9ca0585d
---

## CLAIMS

### Artifact layout

- `download-artifact`'s `merge-multiple` input is documented: "If true, the downloaded artifacts will be in the same directory specified by path. If false, the downloaded artifacts will be extracted into individual named directories within the specified path." Default is `'false'`. [dl-readme]
- With `pattern: candidate-digest-*`, `merge-multiple: false`, `path: /tmp/x`, each matched artifact lands at `/tmp/x/<artifact-name>/<files>` — files are NOT flattened into `/tmp/x`. [dl-readme]
- The README's directory-tree example for multiple artifacts `Artifact-A`/`Artifact-B` into `etc/usr/artifacts/` shows `etc/usr/artifacts/Artifact-A/...` and `etc/usr/artifacts/Artifact-B/...`. [dl-readme]
- Documented exception: "When downloading a single artifact (by name or ID), it will always be extracted directly to the specified path" — so the nesting only appears in the multi-artifact case. [dl-readme]
- The README's `merge-multiple: true` example (`pattern: my-artifact-*`) is the flattening case, producing `my-artifact/file-macos-latest.txt` etc. Reading that example without noting the `true` is the easy way to get this backwards. [dl-readme]

### Artifact internal paths

- `upload-artifact` roots the artifact at the least common ancestor: "If multiple paths are provided as input, the least common ancestor of all the search paths will be used as the root directory of the artifact." [ul-readme]
- For a single file path such as `<dir>/core`, the LCA is `<dir>`, so the artifact's internal path is `core` at the artifact root. Combined with the download nesting above, `name: candidate-digest-core` + `path: <dir>/core` downloads to `/tmp/x/candidate-digest-core/core`. [ul-readme]
- Wildcards change the root: "If a wildcard pattern is used, the path hierarchy will be preserved after the first wildcard pattern" — `path/to/*/directory/foo?.txt` uploads as `some/directory/foo1.txt`. [ul-readme]

### needs context, always(), skipped jobs

- Skip propagates through `needs` by default: "If a job fails or is skipped, all jobs that need it are skipped unless the jobs use a conditional expression that causes the job to continue... If you would like a job to run even if a job it is dependent on did not succeed, use the `always()` conditional expression." So `if: always() && <expr>` DOES run the dependent job when a needed job was skipped. [gh-needs]
- `always()` "Causes the step to always execute, and returns `true`, even when canceled." Docs caution: "Avoid using `always` for any task that could suffer from a critical failure, for example: getting sources, otherwise the workflow may hang until it times out." [gh-expressions]
- `needs.<job_id>.result` possible values are exactly `success`, `failure`, `cancelled`, `skipped`. [gh-contexts]
- The official example `needs` context payload shows a FAILED job carrying `"outputs": {}` — an empty object, not populated outputs. Referencing `needs.<job>.outputs.<x>` on such a job yields an empty string in expression interpolation (GitHub expressions coerce a missing property to empty when interpolated). This is the key release-pipeline hazard: an `if: always() && ...` gate that reads a digest output from a skipped/failed job silently gets `''`, not an error. [gh-contexts]
- Practical consequence: gate on `needs.<job>.result == 'success'` explicitly rather than relying on the output being non-empty, and never let an empty digest flow into a tag/promote step.

### Matrix result

- "When using a matrix, job outputs will be combined from all jobs inside the matrix" — a matrix job is one node in the `needs` graph, not N nodes. [gh-job-outputs]
- With `fail-fast: false` and SOME legs failing, the dependent job sees `needs.<matrixjob>.result == 'failure'`. The aggregate result of the matrix node is a failure if any leg failed; there is no per-leg result exposed through `needs`. [gh-contexts][gh-job-outputs]
- Corollary worth flagging in review: because matrix outputs are COMBINED across legs and last-writer-wins for a given output name, a matrix job that sets the same output name in every leg gives a nondeterministic value — matrix legs should publish per-leg artifacts, not same-named job outputs.

### docker/build-push-action digest

- `build-push-action` documents `digest` only as "Image digest" (String) — the README is silent on manifest-list vs single-platform. [bp-readme]
- Source resolution: `main.ts` calls `toolkit.buildxBuild.resolveDigest(metadata)`, and actions-toolkit's `resolveDigest` returns `metadata['containerimage.digest']`. So `outputs.digest` is exactly buildkit's `containerimage.digest` build-metadata key. [bp-src][toolkit-src]
- For a multi-platform build pushed in one step, `containerimage.digest` is the digest of the manifest LIST / OCI index that was pushed, not a per-platform image manifest. In the matrix "push by digest" pattern (`outputs=type=image,push-by-digest=true`, no tags) each per-platform job's digest is instead that leg's single-platform manifest digest. Which one you get depends on what that build step pushed. [bp-src][toolkit-src]
- The value INCLUDES the `sha256:` prefix. The canonical Docker multi-platform workflow strips it with the bash expansion `${digest#sha256:}` before using it as a filename, then re-adds `@sha256:%s` when calling `imagetools create` — that strip/re-add round trip is only necessary because the prefix is present. [bp-src]

### imagetools inspect --format

- `.Manifest` "provides the manifest or manifest list"; `--format` "Defaults to `{{.Manifest}}` if unset." [imagetools-inspect]
- Verified locally (buildx v0.36.1) against `alpine:3.19`: `--format '{{json .Manifest}}'` returns `"mediaType": "application/vnd.oci.image.index.v1+json"` with the index digest — so on a multi-arch tag `.Manifest.Digest` IS the manifest-list/index digest, matching what `build-push-action` emits for a multi-arch push. [local-verify]
- Cross-checked against the registry itself: Docker Hub returned `docker-content-digest: sha256:6baf43584bcb78f2e5847d1de515f23499913ac9f12bdf834811a3145eb11ca1` with `content-type: application/vnd.oci.image.index.v1+json` for `library/alpine:3.19`, byte-identical to the `imagetools` value. [local-verify]
- Output shape, measured with `wc -c`/`xxd`: `--format '{{json .Manifest.Digest}}'` emits 73 bytes = `"` + 71-char digest + `"`, last byte `0x22`. The bare `--format '{{.Manifest.Digest}}'` emits 71 bytes. **Neither has a trailing newline.** [local-verify]
- Review consequence: `$(docker buildx imagetools inspect --format '{{json .Manifest.Digest}}' ...)` yields a JSON-QUOTED string. Comparing it directly against `steps.push.outputs.digest` (unquoted) fails. Strip the quotes (`tr -d '"'`, `jq -r`) or use the non-json form. Do NOT add a newline-stripping step expecting one to be there.

### imagetools create and buildx setup

- `imagetools create` "Create a new manifest list based on source manifests. The source manifests can be manifest lists or single platform distribution manifests and must already exist in the registry where the new manifest is created." It is a registry-side operation. [imagetools-create]
- Verified locally: `docker buildx imagetools create --dry-run --tag localhost:5000/test:x alpine:3.19` succeeded (exit 0, emitted the assembled manifest JSON) with ONLY the built-in `default`/docker driver present — no `docker buildx create` builder and no `setup-buildx-action` equivalent. [local-verify]
- Conclusion: `setup-buildx-action` is NOT required for a job that only runs `imagetools create`/`inspect`. It IS still required for actual builds needing the docker-container driver (multi-platform build, cache exporters). A merge/promote job that only assembles manifests can skip it; keeping it is harmless but not load-bearing.

## SOURCES

**dl-readme**
URL: https://raw.githubusercontent.com/actions/download-artifact/main/README.md
Accessed: 2026-08-17
Quote: "When multiple artifacts are matched, this changes the behavior of the destination directories. If true, the downloaded artifacts will be in the same directory specified by path. If false, the downloaded artifacts will be extracted into individual named directories within the specified path. Note: When downloading a single artifact (by name or ID), it will always be extracted directly to the specified path. Optional. Default is 'false'"
Quote: "If the `name` input parameter is not provided, all artifacts will be downloaded. To differentiate between downloaded artifacts, by default a directory denoted by the artifacts name will be created for each individual artifact."

**ul-readme**
URL: https://raw.githubusercontent.com/actions/upload-artifact/main/README.md
Accessed: 2026-08-17
Quote: "If multiple paths are provided as input, the least common ancestor of all the search paths will be used as the root directory of the artifact. Exclude paths do not affect the directory structure."

**gh-contexts**
URL: https://raw.githubusercontent.com/github/docs/main/content/actions/reference/workflows-and-actions/contexts.md
Accessed: 2026-08-17
Quote: "`needs.<job_id>.result` | `string` | The result of a job that the current job depends on. Possible values are `success`, `failure`, `cancelled`, or `skipped`."
Quote (example contents of the needs context): "\"deploy\": { \"result\": \"failure\", \"outputs\": {} }"

**gh-needs**
URL: https://raw.githubusercontent.com/github/docs/main/data/reusables/actions/jobs/section-using-jobs-in-a-workflow-needs.md
Accessed: 2026-08-17
Quote: "If a job fails or is skipped, all jobs that need it are skipped unless the jobs use a conditional expression that causes the job to continue. If a run contains a series of jobs that need each other, a failure or skip applies to all jobs in the dependency chain from the point of failure or skip onwards. If you would like a job to run even if a job it is dependent on did not succeed, use the `always()` conditional expression in `jobs.<job_id>.if`."

**gh-expressions**
URL: https://docs.github.com/en/actions/reference/workflows-and-actions/expressions
Accessed: 2026-08-17
Quote: "Causes the step to always execute, and returns `true`, even when canceled." / "Avoid using `always` for any task that could suffer from a critical failure, for example: getting sources, otherwise the workflow may hang until it times out."

**gh-job-outputs**
URL: https://raw.githubusercontent.com/github/docs/main/data/reusables/actions/jobs/section-defining-outputs-for-jobs.md
Accessed: 2026-08-17
Quote: "Matrices can be used to generate multiple outputs of different names. When using a matrix, job outputs will be combined from all jobs inside the matrix."

**bp-readme**
URL: https://raw.githubusercontent.com/docker/build-push-action/master/README.md
Accessed: 2026-08-17
Quote: "| `digest`   | String  | Image digest          |"

**bp-src**
URL: https://raw.githubusercontent.com/docker/build-push-action/master/src/main.ts
Accessed: 2026-08-17
Quote: "const digest = toolkit.buildxBuild.resolveDigest(metadata); ... core.setOutput('digest', digest);"

**toolkit-src**
URL: https://raw.githubusercontent.com/docker/actions-toolkit/main/src/buildx/build.ts
Accessed: 2026-08-17
Quote: "public resolveDigest(metadata?: BuildMetadata): string | undefined { ... if ('containerimage.digest' in metadata) { return metadata['containerimage.digest']; } return undefined; }"

**imagetools-inspect**
URL: https://docs.docker.com/reference/cli/docker/buildx/imagetools/inspect/
Accessed: 2026-08-17
Quote: "Format the output using the given Go template. Defaults to `{{.Manifest}}` if unset." / ".Manifest: provides the manifest or manifest list"

**imagetools-create**
URL: https://docs.docker.com/reference/cli/docker/buildx/imagetools/create/
Accessed: 2026-08-17
Quote: "Create a new manifest list based on source manifests. The source manifests can be manifest lists or single platform distribution manifests and must already exist in the registry where the new manifest is created."

**local-verify**
URL: local execution, docker buildx v0.36.1 (BuildKit v0.32.2), builders: `default` docker driver only
Accessed: 2026-08-17
Quote: `docker buildx imagetools inspect --format '{{json .Manifest.Digest}}' alpine:3.19` -> 73 bytes, `"sha256:6baf43584bcb78f2e5847d1de515f23499913ac9f12bdf834811a3145eb11ca1"`, final byte 0x22, no 0x0a. Bare form -> 71 bytes. `{{json .Manifest}}` mediaType `application/vnd.oci.image.index.v1+json`. Registry `docker-content-digest` header identical. `imagetools create --dry-run --tag localhost:5000/test:x alpine:3.19` exit 0 with no buildx-created builder.

## SYNTHESIS

Three of these are latent release-pipeline footguns that look correct in review:

1. **The download nesting.** The most-copied snippet in the wild is the `merge-multiple: true` flattening example. If a promote job globs `/tmp/x/*` expecting digest files but the workflow uses the default `false`, it gets directories, not files. `cat /tmp/x/*` then fails or produces garbage rather than erroring loudly.

2. **Empty outputs from a skipped job under `always()`.** `if: always() && ...` is exactly the idiom used to make a promote job run after a partially-failed build matrix — and it is the idiom that lets an empty digest reach a tagging step. The docs show the failed job with `"outputs": {}`, and expression interpolation turns that into `''` rather than failing. A promotion bound to "build digests, not mutable tags" (the stated intent of this branch) is only as strong as its check that the digest is actually non-empty AND that the producing job's `result == 'success'`. An empty digest concatenated into `image@sha256:` is a malformed ref that some tooling will reject loudly and some will resolve surprisingly.

3. **JSON quoting on the digest comparison.** If the pipeline verifies "the tag I promoted points at the digest I built" by comparing `imagetools inspect --format '{{json .Manifest.Digest}}'` against `outputs.digest`, the comparison is `"sha256:abc"` vs `sha256:abc` and NEVER matches — a verification step that always fails, or worse, one whose failure is swallowed. There is also no trailing newline to strip, so a defensive `tr -d '\n'` is a no-op that can mislead a reader into thinking the quoting was handled.

The good news for the review: `.Manifest.Digest` on a multi-arch tag and `build-push-action`'s `outputs.digest` for a multi-arch push are genuinely the same index digest (verified against the registry's own `docker-content-digest`), so digest-binding promotion is sound in principle. And a promote-only job needs no `setup-buildx-action`, so its absence there is not a defect.
