#!/bin/bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/cleanup-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

export CODE_ROOT="$TEST_ROOT/code"
export NESTED_ARTIFACT_MAXDEPTH=8
export REFRESH_CACHE_AFTER_CLEANUP=false
mkdir -p "$CODE_ROOT"

# shellcheck source=../bin/.local/bin/cleanup
source "$REPO_ROOT/bin/.local/bin/cleanup"

fail() {
    echo "not ok - $*" >&2
    exit 1
}

assert_eq() {
    local expected=$1 actual=$2 message=$3
    [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_exists() {
    [[ -e "$1" ]] || fail "$2"
}

assert_absent() {
    [[ ! -e "$1" ]] || fail "$2"
}

old_date="2000-01-01 00:00:00 UTC"

mkdir -p "$CODE_ROOT/elixir-stale/_build" "$CODE_ROOT/elixir-stale/deps"
touch "$CODE_ROOT/elixir-stale/mix.exs" "$CODE_ROOT/elixir-stale/lib.ex"
touch -d "$old_date" "$CODE_ROOT/elixir-stale/mix.exs" "$CODE_ROOT/elixir-stale/lib.ex"
printf 'build\n' > "$CODE_ROOT/elixir-stale/_build/payload"
printf 'deps\n' > "$CODE_ROOT/elixir-stale/deps/payload"

mkdir -p "$CODE_ROOT/elixir-active/_build" "$CODE_ROOT/elixir-active/src"
touch "$CODE_ROOT/elixir-active/mix.exs" "$CODE_ROOT/elixir-active/src/live.erl"
printf 'active\n' > "$CODE_ROOT/elixir-active/_build/payload"

mkdir -p "$CODE_ROOT/not-elixir/_build"
touch -d "$old_date" "$CODE_ROOT/not-elixir/_build"

mkdir -p "$CODE_ROOT/unity-stale/Assets" \
    "$CODE_ROOT/unity-stale/ProjectSettings" \
    "$CODE_ROOT/unity-stale/Library"
touch "$CODE_ROOT/unity-stale/Assets/main.cs"
touch -d "$old_date" "$CODE_ROOT/unity-stale/Assets/main.cs"
printf 'unity\n' > "$CODE_ROOT/unity-stale/Library/payload"

mkdir -p "$CODE_ROOT/unity-active/Assets" \
    "$CODE_ROOT/unity-active/ProjectSettings" \
    "$CODE_ROOT/unity-active/Library"
touch "$CODE_ROOT/unity-active/Assets/current-texture.png"
printf 'active unity\n' > "$CODE_ROOT/unity-active/Library/payload"

mkdir -p "$CODE_ROOT/not-unity/Library"
touch -d "$old_date" "$CODE_ROOT/not-unity/Library"

mkdir -p "$CODE_ROOT/group/nested/more/stale-node/node_modules"
touch "$CODE_ROOT/group/nested/more/stale-node/index.ts"
touch -d "$old_date" "$CODE_ROOT/group/nested/more/stale-node/index.ts"
printf 'dependency\n' > "$CODE_ROOT/group/nested/more/stale-node/node_modules/payload"

mkdir -p "$CODE_ROOT/too/deep/for/the/scan/node_modules"
touch "$CODE_ROOT/too/deep/for/the/scan/index.ts"
touch -d "$old_date" "$CODE_ROOT/too/deep/for/the/scan/index.ts"

stale_nodes=$(find_stale_node_modules | tr '\0' '\n')
assert_eq "$CODE_ROOT/group/nested/more/stale-node/node_modules" "$stale_nodes" \
    "Node module discovery must include depth 5 under CODE_ROOT and exclude depth 6"

stale_builds=$(find_stale_project_artifacts _build _is_elixir_project | tr '\0' '\n')
assert_eq "$CODE_ROOT/elixir-stale/_build" "$stale_builds" \
    "Elixir discovery must spare active and non-Elixir projects"

stale_deps=$(find_stale_project_artifacts deps _is_elixir_project | tr '\0' '\n')
assert_eq "$CODE_ROOT/elixir-stale/deps" "$stale_deps" \
    "Elixir deps discovery must require a sibling mix.exs"

stale_unity=$(find_stale_project_artifacts Library _is_unity_project | tr '\0' '\n')
assert_eq "$CODE_ROOT/unity-stale/Library" "$stale_unity" \
    "Unity discovery must require Assets and ProjectSettings"

deep_parent="$CODE_ROOT/python/a/b/c/d/e/f"
mkdir -p "$deep_parent/__pycache__"
printf 'cache\n' > "$deep_parent/__pycache__/payload"
pycache_probe=$(probe_pycache_total)
assert_eq "1" "${pycache_probe%%|*}" \
    "Python cache discovery must reach the configured nested depth"

CACHE_FILE="$TEST_ROOT/cache"
printf '%s\n' \
    "$CACHE_VERSION" \
    "0" \
    "1" \
    "elixir_build:1:1" \
    "elixir_deps:1:1" \
    "unity_library:1:1" \
    "pycache:1:1" \
    "---" > "$CACHE_FILE"

ONLY_MODE=true
ONLY_CAT=([elixir_build]=1)
DRY_RUN=false
ASSUME_YES=true
INCLUDE_TIER_2=false
do_cleanup >/dev/null
assert_exists "$CODE_ROOT/elixir-stale/_build" \
    "Tier-2 artifacts must not be deleted without --include-tier-2"

INCLUDE_TIER_2=true
DRY_RUN=true
preview_file="$TEST_ROOT/preview-output"
do_cleanup > "$preview_file"
preview_output=$(<"$preview_file")
[[ "$preview_output" == *"[preview] would rm -rf each"* ]] \
    || fail "Tier-2 preview must describe the pending deletion"
assert_exists "$CODE_ROOT/elixir-stale/_build" \
    "Preview must preserve the selected artifact"

DRY_RUN=false
do_cleanup >/dev/null
assert_absent "$CODE_ROOT/elixir-stale/_build" \
    "Confirmed tier-2 cleanup must delete the stale selected artifact"
assert_exists "$CODE_ROOT/elixir-active/_build" \
    "Confirmed cleanup must spare active projects"
assert_exists "$CODE_ROOT/unity-active/Library" \
    "Cleanup discovery must spare Unity projects with current non-code assets"

ONLY_CAT=([pycache]=1)
INCLUDE_TIER_2=false
do_cleanup >/dev/null
assert_absent "$deep_parent/__pycache__" \
    "Tier-1 Python cache cleanup must delete matched cache directories"
assert_exists "$CODE_ROOT/elixir-stale/deps" \
    "--only-pycache must not delete another category"

echo "ok - cleanup expansion safety"
