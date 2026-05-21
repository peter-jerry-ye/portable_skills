# Portable Skills

Portable Skills packages small, sandboxed Wasm tools for safe first-pass work
with local files.

The goal is simple: when you receive a file that you do not fully trust yet,
inspect it in a constrained environment first. A skill can read only the
directories you explicitly allow, write only to the output locations you
provide, and produce derivative reports you can review before moving the data
into larger tools or workflows.

## Included Skills

Each skill can be installed and used independently. Start with the skill that
matches the file-handling task; do not combine them unless the user explicitly
needs both tabular-data review and PII review.

### `pure-wasm-csv-skills`

Inspect, clean, validate, summarize, and visualize tabular data.

Use it for:

- checking shape, columns, missing values, distributions, and correlations;
- creating cleaned derivative CSV files without changing the original input;
- generating profile, audit, intake, schema, and quality reports;
- triaging supported workbooks and exporting recommended sheets, native XLSX
  tables, or cached regions to CSV;
- producing reviewable HTML chart and dashboard artifacts.

Start here when the user's file is a table or workbook-like artifact:

```sh
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/input.csv -f json -o output/profile.json
```

### `portable-pii-wasm`

Detect, review, anonymize, and sanitize supported PII in local text artifacts.

Use it for:

- checking files before sharing them in chats, issues, PRs, or vendor handoffs;
- scanning directory trees and writing safe manifests;
- scanning staged or saved unified diffs for supported PII on added lines;
- redacting logs, tickets, configs, JSON, CSV, Markdown, and text files;
- applying repeatable PII policies for presets, entity labels, thresholds, and
  file-tree rules, plus optional user-supplied rule packs;
- optionally adding model-backed span candidates through the same `pii.wasm`
  entry point when the user supplies a local model bundle.

Start here when the user's task is safe-share review or redaction:

```sh
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" check data/ticket.txt --preset=customer_support --format=json --report=safe
```

## Safety Model

Portable Skills are designed around explicit access:

- run the bundled Wasm artifact with a WASIp1-capable runtime;
- grant file access with explicit host-to-guest directory preopens;
- keep input and output directories separate when possible;
- treat generated reports, cleaned files, charts, dashboards, manifests, and
  redacted copies as derivative review artifacts.

The examples use `wasmtime` because its `--dir host::guest` syntax makes
preopens explicit. If `wasmtime` is unavailable, the skill references include
tested fallback patterns for WasmEdge and conditional WAMR/iwasm use.

CSV example:

```sh
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/input.csv -f json -o output/profile.json
```

PII example:

```sh
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" scan data --preset=error_report --manifest=output/pii-report.json --format=json --report=safe
```

If runtime path mapping is confusing, create `data` and `output` under the
current directory. For PII model-backed workflows, also create `model`. Then
map them as `./data::data`, `./output::output`, and, when needed,
`./model::model`.

Do not silently replace these workflows with Python, LibreOffice, shell CSV
pipelines, containers, network PII services, or non-sandboxed parsing when a
runtime is missing. Install or select a compatible WASIp1 runtime first.

## Artifact Checks

Every bundled `.wasm` has a sibling `.wasm.sha256` file and a user-facing
`.version` manifest. Verify checksums from the repository root:

```sh
shasum -a 256 -c pure-wasm-csv-skills/assets/csv.wasm.sha256
shasum -a 256 -c portable-pii-wasm/assets/pii.wasm.sha256
```

If `wasm-tools` is installed, structural validation should also pass:

```sh
wasm-tools validate pure-wasm-csv-skills/assets/csv.wasm
wasm-tools validate portable-pii-wasm/assets/pii.wasm
```

## Boundary

These skills are for portable, sandboxed first-pass file work. They do not
replace full spreadsheet applications, notebook environments, native chart
renderers, document parsers, network PII services, or domain-specific human
review.
