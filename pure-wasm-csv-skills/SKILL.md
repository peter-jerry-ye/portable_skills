---
name: pure-wasm-csv-skills
description: Use the bundled pure WASIp1 s4s-csv tool to inspect, clean, profile, validate, summarize, group, visualize, and safely intake CSV/TSV files plus supported cached-value XLSX/XLSM/ODS sheets without Python, pandas, Plotly, LibreOffice, shell CSV pipelines, or native renderers. Use for portable first-pass analysis of untrusted tabular data, including shape/columns, missingness, numeric/categorical summaries, crosstabs, grouped means, audit/intake bundles, and normalized HTML charts.
---

# Pure Wasm CSV Skills

Use the bundled `assets/s4s-csv.wasm` CLI for portable tabular-data work. The
runtime is pure WASIp1 and needs only `wasmtime` plus explicit preopened
directories.

Resolve the Wasm path relative to this skill directory before running commands:

```sh
wasm=/absolute/path/to/pure-wasm-csv-skills/assets/s4s-csv.wasm
```

## Safety Model

- Prefer this tool for first-pass analysis of unfamiliar or untrusted CSV/TSV,
  XLSX/XLSM, or ODS inputs.
- Use explicit `wasmtime run --dir host::guest` preopens. There is no ambient
  filesystem access under WASIp1.
- Keep input and output directories separate when possible:
  `--dir input::data --dir output::out`.
- Do not use Python, pandas, Plotly, LibreOffice, spreadsheet apps, shell CSV
  pipelines, or native renderers for the initial inspection unless the user asks
  for a non-portable follow-up.

## Fast Paths

For shape and columns:

```sh
wasmtime run --dir input::data "$wasm" file-info data/input.csv -f text
wasmtime run --dir input::data "$wasm" columns data/input.csv -f csv
```

For practical first observations:

```sh
wasmtime run --dir input::data "$wasm" missing data/input.csv -f csv
wasmtime run --dir input::data "$wasm" categorical data/input.csv -f csv
wasmtime run --dir input::data "$wasm" numeric data/input.csv -f csv
wasmtime run --dir input::data "$wasm" crosstab data/input.csv --row species --column island -f csv
wasmtime run --dir input::data "$wasm" groupby data/input.csv --by species --mean body_mass_g,flipper_length_mm -f csv
```

For safe intake into an existing output directory:

```sh
wasmtime run --dir input::data --dir output::out "$wasm" intake data/input.csv -o out/intake --trim --drop-empty-rows --normalize-empty --dedupe --standardize-headers
```

## Command Selection

- `preview`: bounded row/column sample.
- `file-info`: filename, byte size, rows, columns.
- `overview`: shape, duplicate rows, memory estimate, column names.
- `columns`: per-column type, missingness, uniqueness, numeric/text facts.
- `missing`: missing-value totals and per-column counts.
- `numeric`: numeric count, mean, std, quartiles, min/max, skewness, kurtosis.
- `categorical`: supported text/category value-count summaries.
- `crosstab`: row-by-column contingency counts for two categorical columns.
- `groupby`: per-group counts and means for selected numeric columns.
- `clean`: cleaned derivative CSV plus optional cleaning report.
- `quality`: no-rules quality report; use `--fail-on-issues` for gate behavior.
- `validate`: JSON rule-based data-quality gate.
- `schema infer` / `schema check`: reusable table contract workflow.
- `summary`: flat profile summary table for spreadsheet tools.
- `explore`: preview, profile, summary, and dashboard bundle.
- `audit`: cleaned data, cleaning report, profile, summary, and categorical charts.
- `intake`: audit bundle plus schema and optional validation reports.
- `xlsx`: list sheets or export cached `.xlsx`/`.xlsm` worksheet values to CSV.
- `ods`: list sheets or export cached `.ods` table values to CSV.
- `viz`: normalized HTML histogram/box/violin/scatter/line/bar/pie/correlation.
- `dashboard`: normalized HTML dashboard.

## Help

Use the built-in help instead of guessing flags:

```sh
wasmtime run "$wasm" --help
wasmtime run "$wasm" help groupby
wasmtime run "$wasm" crosstab --help
```

## Workbook Boundary

`xlsx`/`ods` support is read-only cached-value intake/export. The tool does not
recalculate formulas, preserve display styling, execute macros/scripts, edit
workbooks, render native charts, or claim spreadsheet display fidelity.

## Chart Boundary

Chart output is deterministic normalized Plotly-compatible HTML. Native
PNG/PDF/SVG rendering and full default Plotly `fig.write_html(...)` byte parity
are out of scope.
