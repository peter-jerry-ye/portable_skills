#!/usr/bin/env bash
set -euo pipefail

wasm="pure-wasm-csv-skills/assets/s4s-csv.wasm"
checksum_file="pure-wasm-csv-skills/assets/s4s-csv.wasm.sha256"
version_file="pure-wasm-csv-skills/assets/s4s-csv.version"
skill_file="pure-wasm-csv-skills/SKILL.md"

case "${1:-all}" in
  shape)
    test -f "README.md"
    test -f "AGENTS.md"
    test -f "LICENSE"
    test -f "NOTICE"
    test -f "$skill_file"
    test -f "$wasm"
    test -f "$checksum_file"
    test -f "$version_file"
    ;;

  artifact)
    sha256sum -c "$checksum_file"

    expected_hash="$(cut -d ' ' -f 1 "$checksum_file")"
    actual_size="$(wc -c < "$wasm" | tr -d ' ')"

    grep -Fx "sha256: $expected_hash" "$version_file"
    grep -Fx "size_bytes: $actual_size" "$version_file"
    grep -Fx "runtime: WASIp1" "$version_file"
    ;;

  smoke)
    wasmtime --version
    wasmtime run "$wasm" --help
    wasmtime run "$wasm" help intake
    ;;

  all)
    "$0" shape
    "$0" artifact
    if command -v wasmtime >/dev/null 2>&1; then
      "$0" smoke
    else
      echo "wasmtime not found; skipping smoke check" >&2
    fi
    ;;

  *)
    echo "usage: $0 [shape|artifact|smoke|all]" >&2
    exit 2
    ;;
esac
