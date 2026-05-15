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

run_e2e() {
  command -v wasmtime >/dev/null 2>&1 || {
    echo "wasmtime is required for e2e checks" >&2
    exit 1
  }

  wasm="pure-wasm-csv-skills/assets/s4s-csv.wasm"
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT

  input_dir="$workdir/input"
  output_dir="$workdir/output"
  mkdir -p "$input_dir" "$output_dir/intake"

  cat >"$input_dir/customers.csv" <<'CSV'
Customer ID,Segment,Revenue,Notes
1,SMB,1200, Active 
2,Enterprise,,Needs review
2,Enterprise,,Needs review
3,SMB,800,
CSV

  if wasmtime run --dir "$input_dir"::data "$wasm" clean data/customers.csv -o out/blocked.csv >/dev/null 2>&1; then
    echo "clean unexpectedly wrote without an output preopen" >&2
    exit 1
  fi

  wasmtime run --dir "$input_dir"::data "$wasm" file-info data/customers.csv -f text >"$workdir/file-info.txt"
  grep -q "Rows: 4" "$workdir/file-info.txt"
  grep -q "Columns: 4" "$workdir/file-info.txt"

  wasmtime run --dir "$input_dir"::data "$wasm" missing data/customers.csv -f csv >"$workdir/missing.csv"
  grep -q "Revenue,2,50.00%" "$workdir/missing.csv"
  grep -q "Notes,1,25.00%" "$workdir/missing.csv"

  wasmtime run --dir "$input_dir"::data --dir "$output_dir"::out "$wasm" intake data/customers.csv -o out/intake --trim --drop-empty-rows --normalize-empty --dedupe --standardize-headers

  cat >"$workdir/expected-cleaned.csv" <<'CSV'
customer_id,segment,revenue,notes
1,SMB,1200,Active
2,Enterprise,,Needs review
3,SMB,800,
CSV
  cmp "$workdir/expected-cleaned.csv" "$output_dir/intake/cleaned.csv"

  test -f "$output_dir/intake/clean-report.json"
  test -f "$output_dir/intake/profile.html"
  test -f "$output_dir/intake/profile.json"
  test -f "$output_dir/intake/profile.txt"
  test -f "$output_dir/intake/schema.json"
  test -f "$output_dir/intake/summary.csv"
  grep -q '"rows": 3' "$output_dir/intake/schema.json"
  grep -q '"name": "customer_id"' "$output_dir/intake/schema.json"
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

  e2e)
    run_e2e
    ;;

  all)
    "$0" shape
    "$0" artifact
    "$0" e2e
    ;;

  *)
    echo "usage: $0 [shape|artifact|e2e|all]" >&2
    exit 2
    ;;
esac
