---
name: pure-wasm-csv-skills
description: Inspect, clean, validate, summarize, and visualize CSV/TSV/custom-delimited tables plus supported cached-value XLSX/XLSM/ODS sheets in a portable WASIp1 sandbox. Use when working with unfamiliar tabular files, spreadsheet intake, data-quality reports, cleaned derivative CSVs, schema checks, grouped summaries, crosstabs, workbook sheet export, or HTML chart/dashboard review without Python, pandas, LibreOffice, or native renderers.
---

# Pure Wasm CSV Skills

Use this skill for first-pass work on tabular files. Treat `csv.wasm` as a
black-box worker: grant only the directories needed, write derivative outputs,
and inspect those outputs before trusting or importing the data elsewhere.

## Quick Start

Resolve the bundled artifact relative to this skill directory. Examples assume
`data/` contains input files and `output/` is for generated artifacts:

```sh
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" profile data/input.csv -f json -o output/profile.json
```

Every path passed to the module is a guest path under an explicit runtime
preopen. There is no ambient filesystem access.

## Workflow Routing

- Unknown table: run `preview`, `file-info` or `overview`, then `profile`.
- Column question: run `columns`, `missing`, `numeric`, or `categorical`.
- Relationship question: run `correlation`, `crosstab`, or `groupby`.
- Cleaning review: run `clean` with `--report`, then run `quality` or
  `validate` on the cleaned output.
- Reusable handoff: run `intake`; use `explore` for broad profiling and
  `audit` when cleaning changes matter.
- Workbook intake: run `workbook sheets`, then export cached values with
  `workbook export`, `xlsx`, or `ods`.
- Visual review: run `viz` or `dashboard` only after confirming the relevant
  columns and data types.

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
- Treat cleaned files, reports, charts, dashboards, and bundles as derivative
  review artifacts.
- Do not substitute Python, pandas, Plotly, LibreOffice, spreadsheet apps,
  shell CSV pipelines, or native renderers for supported first-pass work.

## References

- Read [Usage reference](references/usage.md) when a workflow needs concrete
  command recipes, output guidance, runtime fallbacks, workbook handling,
  dashboard config, or troubleshooting.

## Boundaries

Workbook support is read-only cached-value intake/export. The skill does not
recalculate formulas, execute macros, preserve styling, edit workbooks, render
native charts, or provide spreadsheet display fidelity.

HTML chart/dashboard output is a review artifact. Static PNG/PDF/SVG rendering
and full native chart-renderer parity are outside this skill.
