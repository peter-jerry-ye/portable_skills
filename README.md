# Portable Skills

Portable Skills packages small, sandboxed Wasm tools for safe first-pass work
with local files.

The goal is simple: when you receive a file that you do not fully trust yet,
inspect it in a constrained environment first. A skill can read only the
directories you explicitly allow, write only to the output locations you
provide, and produce derivative reports you can review before moving the data
into larger tools or workflows.

## Included Skills

### `pure-wasm-csv-skills`

Inspect, clean, validate, summarize, and visualize tabular data.

Use it for:

- checking shape, columns, missing values, distributions, and correlations;
- creating cleaned derivative CSV files without changing the original input;
- generating profile, audit, intake, schema, and quality reports;
- exporting supported cached-value workbook sheets to CSV;
- producing reviewable HTML chart and dashboard artifacts.

### `portable-pii-wasm`

Detect, review, anonymize, and sanitize supported PII in local text artifacts.

Use it for:

- checking files before sharing them in chats, issues, PRs, or vendor handoffs;
- scanning directory trees and writing safe manifests;
- redacting logs, tickets, configs, JSON, CSV, Markdown, and text files;
- applying repeatable PII policies for presets, entity labels, thresholds, and
  file-tree rules;
- optionally adding model-backed span candidates through the same `pii.wasm`
  entry point when the user supplies a local model bundle.

## Safety Model

Portable Skills are designed around explicit access:

- run the bundled Wasm artifact with a WASIp1-capable runtime;
- grant file access with explicit host-to-guest directory preopens;
- keep input and output directories separate when possible;
- treat generated reports, cleaned files, charts, dashboards, manifests, and
  redacted copies as derivative review artifacts.

The examples use `wasmtime` because it is common and its `--dir host::guest`
syntax makes preopens explicit. Any runtime with WASIp1 support is sufficient
if it can provide the same directory access.

Example:

```sh
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/input.csv -f json -o output/profile.json
```

```sh
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" scan data --preset=error_report --manifest=output/pii-report.json
```

If runtime path mapping is confusing, create `data` and `output` under the
current directory. For PII model-backed workflows, also create `model`. Then
map them as `./data::data`, `./output::output`, and, when needed,
`./model::model`.

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
