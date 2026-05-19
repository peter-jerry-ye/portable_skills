---
name: portable-pii-wasm
description: Detect, review, anonymize, and sanitize supported PII in local text files or directory trees with a portable offline workflow. Use when checking files before sharing, creating safe reports, redacting logs/tickets/configs/JSON/CSV/Markdown, scanning directories for supported personal data or secrets, or applying repeatable PII policies without a Python PII runtime.
---

# Portable PII Wasm

Use this skill to find or redact supported personal information before sharing
text, logs, tickets, configs, JSON, CSV, Markdown, or local file trees. Treat
the packaged Wasm as a black-box worker: grant only the directories needed and
write redacted outputs separately from inputs.

## Quick Start

Resolve the bundled artifact relative to this skill directory and run it with
explicit WASI preopens. Any WASIp1-capable runtime is sufficient; examples use
`wasmtime` because its `--dir host::guest` syntax is explicit:

```sh
wasm=/absolute/path/to/portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" check data/ticket.txt --preset=customer_support --format=json --report=safe
```

For directory redaction, keep the redacted copy and manifest outside the input
mount:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" sanitize data --output=output/redacted --preset=error_report --manifest=output/manifest.json
```

Every path passed to the Wasm module is a guest path under the runtime's
preopen mapping. There is no ambient filesystem access.

## Workflows

- Pre-share check: run `check` with `--report=safe`; summarize entity types,
  counts, and affected path, not raw matched text.
- Directory review: run `scan`, include a manifest, and report skipped files or
  bounds that make the result incomplete.
- Redaction: run `anonymize` for one text artifact or `sanitize` for a file
  tree; keep outputs outside the input directory.
- Repeatable policy: use `--policy` for preset/entity selection, score
  threshold, report mode, replacement text, hidden-file rules, excludes, and
  maximum file size.
- Model-backed review/redaction: use `--model-dir=model` with `analyze`,
  `anonymize`, `check`, or `sanitize` when the user supplies a local
  token-classification model bundle. Keep model spans separate from
  deterministic PII findings in summaries.
- Capability check: run `capabilities --format=json` before relying on exact
  entity labels.

Presets cover common workflows:

- `customer_support`: support tickets and chat transcripts.
- `error_report`: logs, traces, crash reports, and diagnostic payloads.
- `financial_document`: invoices, payment instructions, and billing text.
- `healthcare_admin`: administrative identifiers, not clinical concepts.
- `identity_verification`: KYC/onboarding identifiers.

## Safe Reporting

Use `--report=safe` for anything that may be pasted into chat, issues, PRs, CI
logs, or vendor handoffs. Safe summaries should include entity type, count,
path, span, score, replacement placeholder, skipped files, and output paths, but
not raw matched PII.

Use `--report=full` only for local debugging when the user explicitly needs raw
matches. Do a manual safe-share review before posting any output externally.

If runtime path mapping is confusing, put input files under `./data`, generated
files under `./output`, and model files under `./model`, then preopen them as
`data`, `output`, and `model`.

## References

- [Usage reference](references/usage.md): command examples, policy files,
  model-backed workflow setup, directory scanning, and troubleshooting.

## Boundaries

This is supported-PII detection, not a guarantee that all personal information
has been removed. Names, organizations, full addresses, general locations,
diagnoses, clinical concepts, arbitrary secrets, PDF/DOCX parsing, and network
service access are outside scope unless `capabilities` says otherwise.

Model-backed spans are experimental review candidates and are reported
separately from deterministic PII findings.

Redaction is text-level and does not preserve structured document formats.
