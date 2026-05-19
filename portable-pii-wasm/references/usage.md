# PII Usage Reference

Use this reference when the top-level skill file is not detailed enough. The
CLI usage text and `capabilities` output are the source of truth:

```sh
wasmtime run portable-pii-wasm/assets/pii.wasm
wasmtime run portable-pii-wasm/assets/pii.wasm capabilities --format=json
```

Any WASIp1-capable runtime is sufficient. These examples suggest `wasmtime`
because its directory preopen syntax is explicit.

## Runtime Pattern

Use guest paths inside the module and map host directories explicitly:

```sh
mkdir -p data output model
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

For troubleshooting, keep `data`, `output`, and, when needed, `model` directly
under the current directory until the path mapping is clear.

## Choosing Commands

- `analyze`: report findings for one text file. Use `--report=safe` unless raw
  matched text is explicitly needed for local debugging.
- `check`: safe share gate for one text file. It exits nonzero when supported
  PII is found.
- `anonymize`: write redacted text for one input file.
- `scan`: scan one file or a directory tree and optionally write a safe
  manifest.
- `sanitize`: write a redacted directory or file copy and optionally write a
  safe manifest.
- `capabilities`: list supported entity labels and presets.
- `selftest`: run an in-runtime smoke check.

## Single-File Workflows

```sh
wasmtime run --dir ./data::data "$wasm" analyze data/ticket.txt --preset=customer_support --format=json --report=safe
wasmtime run --dir ./data::data "$wasm" check data/ticket.txt --preset=customer_support --format=json --report=safe
wasmtime run --dir ./data::data --dir ./output::output "$wasm" anonymize data/ticket.txt --preset=customer_support --replacement="<PII>" --format=json --report=safe > output/ticket-report.json
```

Safe reports omit raw matched text. They include metadata such as entity type,
span, score, replacement placeholder, counts, and paths.

## Directory Workflows

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" scan data --preset=error_report --manifest=output/scan.json --format=json --report=safe
wasmtime run --dir ./data::data --dir ./output::output "$wasm" sanitize data --output=output/redacted --preset=error_report --manifest=output/sanitize.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" sanitize data --output=output/redacted --preset=error_report --dry-run --manifest=output/dry-run.json
```

`scan` and `sanitize` support `--include-hidden`, `--exclude=name,path`, and
`--max-bytes=N`. Files skipped by size or type are not clean; include them in
the user-facing summary.

Keep manifests outside the scanned or sanitized input path. Keep sanitized
output outside the input path.

## Presets and Entities

Use presets when the workflow is clear:

- `customer_support`: support tickets and chat transcripts.
- `error_report`: logs, traces, crash reports, and diagnostic payloads.
- `financial_document`: invoices, payment instructions, and billing text.
- `healthcare_admin`: administrative identifiers, not clinical concepts.
- `identity_verification`: onboarding and identity checks.

Use `--entities=email,phone,ip` only when the user needs a narrow check. Run
`capabilities --format=json` before relying on exact entity names.

## Policy Files

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
wasmtime run --dir ./data::data --dir ./output::output "$wasm" scan data --policy=data/pii-policy.json --manifest=output/scan.json
```

## Model-Backed Candidates

When the user supplies a local token-classification model bundle, map it under
`model` and pass `--model-dir=model` to `analyze`, `anonymize`, `check`, or
`sanitize`:

```sh
wasmtime run --dir ./data::data --dir ./output::output --dir ./model::model \
  "$wasm" check data/note.txt --model-dir=model --format=json --report=safe
```

Model-backed spans are experimental review candidates. Keep them separate from
deterministic PII findings in summaries and do not present them as guaranteed
PII labels.

## Troubleshooting

- If the module cannot open a file, check that the guest path starts under a
  preopened directory such as `data/`, `output/`, or `model/`.
- If a directory scan misses hidden files, rerun with `--include-hidden` only
  when hidden files are in scope.
- If reports are too broad, use a narrower preset, explicit `--entities`, or a
  higher `--min-score`.
- If output may be pasted outside the local machine, use `--report=safe`.
