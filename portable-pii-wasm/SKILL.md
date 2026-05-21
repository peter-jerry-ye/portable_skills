---
name: portable-pii-wasm
description: Detect, review, anonymize, and sanitize supported PII in local text files, directory trees, and unified diffs with a portable offline WASIp1 workflow. Use when checking files before sharing, creating safe reports, redacting logs/tickets/configs/JSON/CSV/Markdown/text, scanning directories or staged diffs for supported personal data or narrow secret formats, applying repeatable policies or rule packs, or using local model-backed span candidates without Python PII libraries or network services.
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

## Runtime Fallback

Use runtimes in this order:

1. `wasmtime`: `--dir ./data::data`
2. `wasmedge`: `--dir data:./data`
3. `iwasm`: `--map-dir=data::./data`, only after `selftest` or
   `capabilities` succeeds

If none are available, stop and report that a compatible WASIp1 runtime is
required. Do not substitute Python PII libraries, containers, network PII
services, shell parsing, or non-sandboxed file handling.

## Workflow Routing

- Pre-share check: run `check` with `--report=safe`; summarize entity types,
  counts, affected paths, and limitations, not raw matched text.
- Single-file review: run `analyze`; use `--report=full` only for explicit
  local debugging.
- Single-file redaction: run `anonymize` and keep the report with the redacted
  output.
- Directory review: run `scan` with a manifest; report skipped files and scan
  bounds.
- Diff review: run `scan --diff` on a unified diff file or stdin; report that
  only added lines were scanned.
- Directory redaction: run `sanitize` into an output path outside the input
  tree.
- Repeatable policy: use `policy-template` to create a starter policy, then
  reuse `--policy` for presets, entities, score thresholds, report mode,
  replacement text, excludes, hidden-file handling, size limits, and rule packs.
- Custom workflow rules: use `--rule-pack` only for user-supplied regex rules,
  denylists, and allowlists; summarize them as custom matches, not public PII
  entities.
- Model-backed candidates: use `--model-dir=model` only when the user provides
  a local model bundle; keep model spans separate from deterministic findings.
- Capability check: run `capabilities --format=json` before relying on exact
  entity labels.
- Demo commands: do not use `ner-demo` or `presidio-transformers-demo` for
  normal safe-share work.

## Safe Reporting

Use `--report=safe` for anything that may be pasted into chat, issues, PRs,
logs, or handoffs. Safe summaries can include entity type, count, path, span
or line-local span, score, replacement placeholder, skipped files, output
paths, custom/model sections, and scope limits. They must not echo raw matched
PII.

Final summaries should include the gate outcome, entity counts, affected paths
or diff scope, report paths, skipped-file or model scope, and caveats. Do not
offer extra redaction or cleanup unless the user asked for it.

## References

- Read [Usage reference](references/usage.md) for recipes, policy files,
  model-backed setup, directory scanning, or troubleshooting.
- Read [Runtime setup](references/runtime.md) when Wasmtime is missing.

## Boundaries

This is supported-PII detection, not a guarantee that all personal information
has been removed. Names, organizations, full addresses, general locations,
diagnoses, clinical concepts, arbitrary secrets, generic environment-variable
heuristics, PDF/DOCX parsing, and network service access are outside scope
unless `capabilities` says otherwise.

Model-backed spans are experimental review candidates and are reported
separately from deterministic findings. Redaction is text-level and does not
preserve structured document formats.
