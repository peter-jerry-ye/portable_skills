#!/usr/bin/env bash
set -euo pipefail

check_sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$1"
  else
    shasum -a 256 -c "$1"
  fi
}

require_wasm_artifacts() {
  found=0
  while IFS= read -r -d '' wasm; do
    found=1
    test -f "${wasm}.sha256"
  done < <(find . -path ./.git -prune -o -type f -name '*.wasm' -print0)

  if [[ "$found" -eq 0 ]]; then
    echo "no .wasm artifacts found" >&2
    exit 1
  fi
}

case "${1:-all}" in
  shape)
    test -f "README.md"
    test -f "AGENTS.md"
    test -f "LICENSE"
    test -f "NOTICE"
    find . -path ./.git -prune -o -type f -name 'SKILL.md' -print -quit | grep -q .
    require_wasm_artifacts
    ;;

  artifact)
    require_wasm_artifacts
    while IFS= read -r -d '' wasm; do
      check_sha256_file "${wasm}.sha256"
      wasm-tools validate "$wasm"
    done < <(find . -path ./.git -prune -o -type f -name '*.wasm' -print0)
    ;;

  all)
    "$0" shape
    "$0" artifact
    ;;

  *)
    echo "usage: $0 [shape|artifact|all]" >&2
    exit 2
    ;;
esac
