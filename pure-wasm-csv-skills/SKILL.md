---
name: pure-wasm-csv-skills
description: Inspect, clean, validate, summarize, and visualize CSV/TSV/custom-delimited tables plus supported cached-value XLSX/XLSM/ODS sheets, native XLSX tables, and cached workbook regions in a portable WASIp1 sandbox. Use when working with unfamiliar tabular files, spreadsheet intake, data-quality reports, cleaned derivative CSVs, schema checks, grouped summaries, crosstabs, workbook triage/export, or HTML chart/dashboard review without Python CSV parsing, pandas, LibreOffice, or native renderers.
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

## Runtime Fallback

Use runtimes in this order:

1. `wasmtime`: `--dir ./data::data`
2. `wasmedge`: `--dir data:./data`
3. `iwasm`: `--map-dir=data::./data`, only after `iwasm ... "$wasm" --help`
   succeeds

If none are available, stop and report that a compatible WASIp1 runtime is
required. Do not substitute Python CSV parsing, pandas, LibreOffice,
spreadsheet apps, shell CSV pipelines, containers, or non-sandboxed parsing.

## Workflow Routing

- Unknown table: run `profile` first. It includes shape, columns, missingness,
  duplicate count, summaries, and quality signals. Add `preview`, `file-info`,
  `columns`, or `missing` only when separate review artifacts are useful.
- Column question: run `columns`, `missing`, `numeric`, or `categorical`.
- Relationship question: run `correlation`, `crosstab`, or `groupby`.
- Cleaning review: run `clean` with `--report`, then run `quality` or
  `validate` on the cleaned output.
- Reusable handoff: run `intake`; use `explore` for broad profiling and
  `audit` when cleaning changes matter.
- Workbook intake: run `workbook triage` when the right sheet, native XLSX
  table, or cached region is unclear; use `workbook sheets`, `workbook tables`,
  and `workbook regions` for inventory.
- Workbook export: use `workbook export --recommended` after triage, or export
  explicitly with `--sheet`, `--sheet-index`, `--table`, or `--region`.
- Workbook as table input: run normal table commands directly with
  `--recommended`, `--sheet`, `--sheet-index`, `--table`, or `--region`.
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
- Final summaries should include artifact paths, key counts or selector
  choices, scope limits, and caveats. Do not offer a follow-up cleanup unless
  the user asked for it.
- Do not substitute Python CSV parsing, pandas, Plotly, LibreOffice,
  spreadsheet apps, shell CSV pipelines, or native renderers for supported
  first-pass work.

## References

- Read [Usage reference](references/usage.md) when a workflow needs concrete
  command recipes, output guidance, workbook handling, dashboard config, or
  troubleshooting.
- Read [Runtime setup](references/runtime.md) when Wasmtime is missing.

## Boundaries

Workbook support is read-only cached-value intake/export. `.xlsx`/`.xlsm`
native table refs and cached regions are selectors for tabular values, not
workbook rendering. The skill does not recalculate formulas, execute macros,
preserve styling, edit workbooks, render native charts, or provide spreadsheet
display fidelity. Legacy `.xls` workbooks are outside scope.

HTML chart/dashboard output is a review artifact. Static PNG/PDF/SVG rendering and full native chart-renderer parity are outside this skill.
