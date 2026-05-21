# PII Usage Reference

Use this reference for concrete recipes after `portable-pii-wasm/SKILL.md` has
selected the workflow. CLI usage text and `capabilities` output are the source
of truth for exact flags, entity labels, presets, and experimental features:

```sh
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run "$wasm"
wasmtime run "$wasm" capabilities --format=json
```

## Runtime Pattern

Create separate directories for inputs, outputs, and optional local model
files, then pass guest paths to the module:

```sh
mkdir -p data output model
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

The guest path `data/ticket.txt` is available because `./data` is preopened as
`data`. The module cannot read files outside the directories you map.

## If Wasmtime Is Missing

Use a compatible WASIp1 runtime. Try runtimes in this order:

1. `wasmtime`
2. `wasmedge`
3. `iwasm`

If none are available, stop and report that a WASIp1 runtime is required. Do
not replace this workflow with Python PII libraries, containers, network PII
services, shell parsing, or non-sandboxed file handling.

Equivalent safe-check commands:

```sh
# Wasmtime: host::guest
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe

# WasmEdge: guest:host
wasmedge --dir data:./data --dir output:./output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe

# WAMR/iwasm: guest::host. Verify this runtime with selftest first.
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" selftest --format=json
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

Some iwasm builds do not enable every WebAssembly feature used by an artifact.
If `selftest` or `capabilities` fails, use Wasmtime or WasmEdge instead and
report the runtime incompatibility.

## Choosing Commands

- `analyze`: report findings for one text file. Use `--report=safe` unless raw
  matched text is explicitly needed for local debugging.
- `check`: safe-share gate for one text file. It exits nonzero when supported
  PII is found.
- `anonymize`: emit redacted text and findings for one input file.
- `scan`: scan one file or a directory tree and optionally write a safe
  manifest.
- `sanitize`: write a redacted directory or file copy and optionally write a
  safe manifest.
- `capabilities`: list supported entity labels and presets.
- `selftest`: run an in-runtime smoke check.

## Pre-Share Single-File Check

Use `check` when a file may be pasted into chat, an issue, a PR, or another
handoff:

```sh
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

`check` returns a nonzero exit status when supported PII is found. Treat that
as a useful gate result, not as a command failure. Summaries should include
entity types, counts, affected path, and scope limits without raw matched
values.

## Single-File Review And Redaction

```sh
wasmtime run --dir ./data::data \
  "$wasm" analyze data/ticket.txt --preset=customer_support \
  --format=json --report=safe

wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" anonymize data/ticket.txt --preset=customer_support \
  --replacement="<PII>" --format=json --report=safe \
  > output/ticket-report.json
```

The `anonymize` JSON output contains redacted `text` plus finding metadata.
Keep that output as the review artifact. Use `sanitize` when a user needs a
redacted copy of a file or directory tree. Use `--report=full` only when the
user explicitly needs raw local matches for debugging.

## Directory Scan

```sh
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" scan data --preset=error_report \
  --manifest=output/scan.json --format=json --report=safe
```

`scan` supports `--include-hidden`, `--exclude=name,path`, and
`--max-bytes=N`. Files skipped by size or type are not clean; include skipped
files or configured bounds in the final response.

## Redacted Directory Copy

```sh
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" sanitize data --output=output/redacted \
  --preset=error_report --manifest=output/sanitize.json

wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" sanitize data --output=output/redacted \
  --preset=error_report --dry-run --manifest=output/dry-run.json
```

Keep manifests and redacted outputs outside the input path. The redacted copy
is a derivative artifact for review, not proof that all private information was
removed.

## Presets And Entities

Use presets when the workflow is clear:

- `customer_support`: support tickets and chat transcripts.
- `error_report`: logs, traces, crash reports, and diagnostic payloads.
- `financial_document`: invoices, payment instructions, and billing text.
- `healthcare_admin`: administrative identifiers, not clinical concepts.
- `identity_verification`: onboarding and identity checks.

Use `--entities=email,phone,ip` only when the user needs a narrow check. Run
`capabilities --format=json` before relying on exact entity names.

## Policy Reuse

Policy files make repeatable settings explicit. CLI flags override policy
values.

```json
{
  "preset": "customer_support",
  "format": "json",
  "report": "safe",
  "replacement": "<PII>",
  "min_score": 0.4,
  "context_prefix": 6,
  "context_suffix": 0,
  "include_hidden": false,
  "exclude": ["vendor/generated", "cache"],
  "max_bytes": 1048576
}
```

Example:

```sh
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" scan data --policy=data/pii-policy.json \
  --manifest=output/scan.json
```

When reporting policy-driven results, mention the policy path, preset or
entity scope, skipped files, and output manifest.

## Model-Backed Candidates

When the user supplies a local token-classification model bundle, map it under
`model` and pass `--model-dir=model` to `analyze`, `anonymize`, `check`, or
`sanitize`:

```sh
wasmtime run --dir ./data::data --dir ./output::output --dir ./model::model \
  "$wasm" check data/note.txt --model-dir=model \
  --format=json --report=safe
```

Model-backed spans are experimental review candidates. Keep them separate from
deterministic PII findings in summaries and do not present them as guaranteed
PII labels.

## Safe Final Summaries

When summarizing results, include:

- command outcome and whether supported PII was found;
- entity types and counts;
- affected paths, output paths, and manifest paths;
- skipped files, size limits, hidden-file handling, or model-backed scope;
- clear caveats for unsupported PII classes.

Do not paste raw matched PII from full reports unless the user explicitly asks
for local debugging output and the response will remain local.

## Troubleshooting

- If the module cannot open a file, check that the guest path starts under a
  preopened directory such as `data/`, `output/`, or `model/`.
- Wasmer is not a recommended fallback for these examples. Its `--mapdir`
  behavior has varied across environments; use it only after local smoke
  testing confirms the exact artifact and directory mapping.
- If a directory scan misses hidden files, rerun with `--include-hidden` only
  when hidden files are in scope.
- If reports are too broad, use a narrower preset, explicit `--entities`, or a
  higher `--min-score`.
- If output may be pasted outside the local machine, use `--report=safe`.
