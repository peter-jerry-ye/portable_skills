---
name: portable-pii-wasm
description: Detect, review, anonymize, and sanitize supported PII in local text files and directory trees with a portable offline WASIp1 workflow. Use when checking files before sharing, creating safe reports, redacting logs/tickets/configs/JSON/CSV/Markdown/text, scanning directories for supported personal data or secrets, applying repeatable PII policies, or using local model-backed span candidates without a Python PII runtime.
---

# Portable PII Wasm

Use this skill to find or redact supported personal information before sharing
text artifacts or local file trees. Treat `pii.wasm` as a black-box worker:
grant only the directories needed and write redacted outputs separately from
inputs.

## Quick Start

Resolve the bundled artifact relative to this skill directory. Examples assume
`data/` contains inputs and `output/` is for generated reports or redacted
copies:

```sh
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

Every path passed to the module is a guest path under an explicit runtime
preopen. There is no ambient filesystem access.

## Workflow Routing

- Pre-share check: run `check` with `--report=safe`; summarize entity types,
  counts, affected paths, and limitations, not raw matched text.
- Single-file review: run `analyze`; use `--report=full` only for explicit
  local debugging.
- Single-file redaction: run `anonymize` and keep the report with the redacted
  output.
- Directory review: run `scan` with a manifest; report skipped files and scan
  bounds.
- Directory redaction: run `sanitize` into an output path outside the input
  tree.
- Repeatable policy: use `--policy` for presets, entities, score thresholds,
  report mode, replacement text, excludes, hidden-file handling, and size
  limits.
- Model-backed candidates: use `--model-dir=model` only when the user provides
  a local model bundle; keep model spans separate from deterministic findings.
- Capability check: run `capabilities --format=json` before relying on exact
  entity labels.

## Safe Reporting

Use `--report=safe` for anything that may be pasted into chat, issues, PRs,
logs, or handoffs. Safe summaries can include entity type, count, path, span,
score, replacement placeholder, skipped files, output paths, and scope limits.
They must not echo raw matched PII.

## References

- [Usage reference](references/usage.md): task recipes, policy files, runtime
  fallbacks, model-backed workflow setup, directory scanning, and
  troubleshooting.

## Boundaries

This is supported-PII detection, not a guarantee that all personal information
has been removed. Names, organizations, full addresses, general locations,
diagnoses, clinical concepts, arbitrary secrets, PDF/DOCX parsing, and network
service access are outside scope unless `capabilities` says otherwise.

Model-backed spans are experimental review candidates and are reported
separately from deterministic findings. Redaction is text-level and does not
preserve structured document formats.
