# BeeLlama runtime packaging report

## Delivered

`bin/.local/bin/llama-bee-start` is the dotfiles-owned BeeLlama launcher. It
derives the applications checkout from `$HOME` (with `LLAMA_BEE_APPLICATIONS_DIR`
and `LLAMA_BEE_DIR` overrides), builds one quoted argv array, and exposes that
array through `--print-command` and `--dry-run`. On a real launch it validates
the GPU1 budget, exports GPU1 visibility by default, preserves the established
line-buffered srv/slot log filtering, and `exec`s `llama-server` so systemd owns
the actual server process.

The static user-service configuration is canonical under `systemd/` and is
installed through the dedicated no-fold `llama-bee-systemd/` package. It links
only `llama-bee.service` and `10-resources.conf`; it deliberately excludes the
gateway-owned `20-model.conf` model/mmproj override.

The launcher preserves GPU1, 102400 context, 16 checkpoints, 256 checkpoint
spacing, 4096 MiB prompt-cache RAM, q5_0 K/q4_1 V, slots, metrics, `-np 1`,
MTP max 3, the fixed Qwen template with `preserve_thinking`, unlimited engine
reasoning, `--no-host`, `--mlock`, and model/mmproj environment overrides.

## Verification

```bash
bash -n bin/.local/bin/llama-bee-start setup.sh
PYTHONDONTWRITEBYTECODE=1 uv run --no-project python -m unittest discover -s tests -v
systemd-analyze --user verify <staged llama-bee.service with 10-resources.conf>
```

The focused runtime tests prove the critical argv defaults and overrides,
shell quoting with spaces, dry-run parity, service/drop-in content, isolated
no-fold Stow installation without unrelated user units, and absence of the
dynamic `20-model.conf` package file.

No services were enabled, started, restarted, or otherwise modified.
