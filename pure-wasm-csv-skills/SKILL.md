---
name: pure-wasm-csv-skills
description: Inspect, clean, validate, profile, summarize, and visualize CSV/TSV/custom-delimited tables plus supported cached-value XLSX/XLSM/ODS sheets in a portable sandbox. Use when working with unfamiliar tabular data, first-pass spreadsheet intake, data-quality reports, cleaned derivative CSVs, schema checks, grouped summaries, crosstabs, or reviewable HTML chart/dashboard artifacts without relying on Python, pandas, LibreOffice, or native renderers.
---

# Pure Wasm CSV Skills

Use this skill for safe first-pass work with tabular files. Treat the packaged
Wasm as a black-box worker: grant only the directories needed, create
derivative outputs, then review those outputs before trusting or importing the
data elsewhere.

## Quick Start

Resolve the bundled artifact relative to this skill directory and run it with
explicit WASI preopens. Any WASIp1-capable runtime is sufficient; examples use
`wasmtime` because its `--dir host::guest` syntax is explicit:

```sh
wasm=/absolute/path/to/pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/input.csv -f json -o output/profile.json
```

Every path passed to the Wasm module is a guest path under the runtime's
preopen mapping. There is no ambient filesystem access.

## Workflows

- Unknown file: run `preview`, `file-info` or `overview`, then `profile`.
- Column questions: use `columns`, `missing`, `numeric`, `categorical`, or
  `correlation` before generating larger bundles.
- Relationship questions: use `crosstab` for two categorical columns and
  `groupby` for per-group counts and means.
- Cleaning: write a new CSV with `clean`, keep the cleaning report, then run
  `quality`, `schema infer`, or `validate`.
- Review bundles: use `explore` for profiling, `audit` for cleaning review, and
  `intake` for handoff artifacts.
- Workbook intake: list sheets if needed, then export or analyze cached sheet
  values with `workbook`, `xlsx`, or `ods`.
- Spreadsheet handoff: use `summary` for a flat CSV/TSV table of profile facts.
- Visual review: use `viz` or `dashboard` after confirming the source columns
  and output type.

Use built-in help instead of guessing flags:

```sh
wasmtime run "$wasm" --help
wasmtime run "$wasm" help intake
wasmtime run "$wasm" help workbook
```

## Safety Rules

- Keep input and output directories separate when possible.
- Prefer JSON or CSV when an agent will inspect results; use HTML for human
  review artifacts.
- Treat cleaned files, reports, charts, dashboards, and intake bundles as
  derivative review artifacts.
- Do not require Python, pandas, Plotly, LibreOffice, spreadsheet apps, shell
  CSV pipelines, or native renderers for supported first-pass work.

If runtime path mapping is confusing, put input files under `./data` and
generated files under `./output`, then preopen them as `data` and `output`.

## References

- [Usage reference](references/usage.md): command examples, output choices,
  workbook handling, dashboard config, and troubleshooting.

## Boundaries

Workbook support is read-only cached-value intake/export. The skill does not
recalculate formulas, execute macros, preserve styling, edit workbooks, render
native charts, or provide spreadsheet display fidelity.

HTML chart/dashboard output is a review artifact. Static PNG/PDF/SVG rendering
and full native chart-renderer parity are outside this skill.
