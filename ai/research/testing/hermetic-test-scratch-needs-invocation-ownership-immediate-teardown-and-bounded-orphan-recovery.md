---
title: "Hermetic test scratch needs invocation ownership, immediate resource teardown, and bounded orphan recovery"
date: 2026-08-12
topic: testing
tags: [testing, temporary-directories, hermeticity, nodejs, cleanup]
status: draft
sources:
  - node-test-runner
  - node-tmpdir
  - bazel-test-encyclopedia
  - go-testing
  - pytest-tmp-path
  - rust-tempfile
  - systemd-tmpfiles
  - github-runner-temp
source_session: 92f0a6cb-32bf-43c9-b09f-63a4c94478d0
---

## CLAIMS

- Node's test runner isolates matching test files in child processes by default and provides scoped cleanup hooks, but it does not create a filesystem sandbox or guarantee cleanup after process death. [node-test-runner]
- On Unix, Node's `os.tmpdir()` honors `TMPDIR`, `TMP`, then `TEMP`; `fs.mkdtemp()` appends random characters to a caller-supplied prefix. A command can therefore place an inherited process tree under one private run root without changing each `mkdtemp(tmpdir())` call site. [node-tmpdir]
- Bazel gives each test a private writable `TEST_TMPDIR`, requires tests to avoid shared `/tmp`, and permits `TEST_TMPDIR` itself to be a symlink. The supplied path is a placement capability, not proof that arbitrary path deletion is safe. [bazel-test-encyclopedia]
- Go's `T.TempDir` couples unique allocation with cleanup after a test and its subtests. pytest namespaces temporary paths by run and test and retains only a bounded number of prior runs. Rust `tempfile` warns that destructors can be skipped after signals and that path cleaners can race path replacement. [go-testing] [pytest-tmp-path] [rust-tempfile]
- systemd-tmpfiles provides age-based cleanup, while GitHub Actions provides a job-owned `runner.temp` that is emptied at job boundaries when permissions allow. Both are recovery layers, not substitutes for normal-path teardown. [systemd-tmpfiles] [github-runner-temp]

## SOURCES

**node-test-runner**
URL: https://nodejs.org/api/test.html
Accessed: 2026-08-12

**node-tmpdir**
URL: https://nodejs.org/api/os.html#ostmpdir
Accessed: 2026-08-12

**bazel-test-encyclopedia**
URL: https://bazel.build/reference/test-encyclopedia
Accessed: 2026-08-12

**go-testing**
URL: https://pkg.go.dev/testing#T.TempDir
Accessed: 2026-08-12

**pytest-tmp-path**
URL: https://docs.pytest.org/en/stable/how-to/tmp_path.html
Accessed: 2026-08-12

**rust-tempfile**
URL: https://docs.rs/tempfile/latest/tempfile/
Accessed: 2026-08-12

**systemd-tmpfiles**
URL: https://www.freedesktop.org/software/systemd/man/systemd-tmpfiles.html
Accessed: 2026-08-12

**github-runner-temp**
URL: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#runner-context
Accessed: 2026-08-12

## SYNTHESIS

Use three explicit ownership levels. A test resource owns its unique `mkdtemp` child and should register cleanup immediately when practical. A canonical test invocation owns one private run root, exports it only to that command's descendants, and removes it in `finally`. A conservative external policy reaps only old, verifiably abandoned invocation roots. This prevents normal-run residue without editing hundreds of test call sites, bounds crash residue without pretending SIGKILL is recoverable in-process, and keeps deletion authority narrower than an ambient temp directory.
