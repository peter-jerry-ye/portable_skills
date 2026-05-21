# CSV Usage Reference

The CLI help remains the source of truth for exact flags:

```sh
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run "$wasm" --help
wasmtime run "$wasm" help profile
wasmtime run "$wasm" help workbook
wasmtime run "$wasm" help xlsx
```

## Runtime Pattern

Create separate input and output directories, then pass guest paths to the
module:

```sh
mkdir -p data output
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" profile data/input.csv -f json -o output/profile.json
```

The guest path `data/input.csv` is available because `./data` is preopened as
`data`. The module cannot read files outside the directories you map.

## If Wasmtime Is Missing

Use a compatible WASIp1 runtime. Try runtimes in this order:

1. `wasmtime`
2. `wasmedge`
3. `iwasm`
4. `pywasm` through `uv run --with pywasm`, only as a slow last resort

If none are available, stop and report that a WASIp1 runtime is required. Do
not replace this workflow with Python CSV parsing, pandas, LibreOffice, shell
CSV tools, or non-sandboxed parsing.

See [Runtime setup](runtime.md) for install commands, runtime-specific
directory mapping, and the `pywasm` runner.

Equivalent profile commands:

```sh
# Wasmtime: host::guest
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" profile data/input.csv -f json -o output/profile.json

# WasmEdge: guest:host
wasmedge --dir data:./data --dir output:./output \
  "$wasm" profile data/input.csv -f json -o output/profile.json

# WAMR/iwasm: guest::host. Verify this runtime with a simple command first.
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" --help
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" profile data/input.csv -f json -o output/profile.json

# pywasm via uv: host::guest. Verify this slower fallback first.
uv run --with pywasm python pure-wasm-csv-skills/scripts/run_pywasm.py \
  "$wasm" --help
uv run --with pywasm python pure-wasm-csv-skills/scripts/run_pywasm.py \
  --dir ./data::data --dir ./output::output \
  "$wasm" profile data/input.csv -f json -o output/profile.json
```

## First Look

Use this for an unfamiliar table. Start with `profile`; it is the fastest
single-command review path and includes file shape, columns, missingness,
duplicate count, summaries, and data-quality signals:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/input.csv -f json -o output/profile.json
```

Add separate artifacts when a human or another tool needs small files for
inspection:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" preview data/input.csv -n 10 --columns 8 -f csv -o output/preview.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" file-info data/input.csv -f json -o output/file-info.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" columns data/input.csv -f csv -o output/columns.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" missing data/input.csv -f csv -o output/missing.csv
```

Read `file-info.json` for file size and shape, `columns.csv` for inferred
types, `missing.csv` for completeness, and `profile.json` for combined column
statistics. Use HTML profile output only when a human needs a review page.

## Cleaning Audit

Write a derivative CSV and keep the cleaning report:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" clean data/raw.csv -o output/clean.csv --trim --drop-empty-rows --normalize-empty --dedupe --standardize-headers --report output/clean-report.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" quality output/clean.csv -f csv -o output/quality.csv --fail-on-issues
```

Summarize what changed from `clean-report.json`. Do not imply the original file
was modified. If `quality` exits nonzero, inspect the output report and include
the issue count or categories in the final response.

## Schema And Quality Gate

Infer a rules file from a reviewed table, then validate later tables against
it:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" schema infer data/baseline.csv -f rules -o output/rules.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" validate data/candidate.csv --rules output/rules.json -f json -o output/validation.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" quality data/candidate.csv -f csv -o output/quality.csv --fail-on-issues
```

Treat validation and quality reports as gates for review, not as proof that the
data is semantically correct.

## Analysis Recipes

Use focused commands before building larger bundles:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" numeric data/input.csv -f csv -o output/numeric.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" categorical data/input.csv -f csv -o output/categorical.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" correlation data/input.csv --columns score,cost -f csv -o output/correlation.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" crosstab data/input.csv --row species --column island -f csv -o output/crosstab.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" groupby data/input.csv --by species --mean body_mass_g,flipper_length_mm -f csv -o output/grouped.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" summary data/input.csv -o output/summary.tsv --delimiter tsv
```

Use `summary` when another tool or reviewer needs a flat TSV of profile facts.

## Bundles

`explore`, `audit`, and `intake` write multiple artifacts. Create output
directories first:

```sh
mkdir -p output/explore output/audit output/intake
wasmtime run --dir ./data::data --dir ./output::output "$wasm" explore data/input.csv -o output/explore --max-plots 6
wasmtime run --dir ./data::data --dir ./output::output "$wasm" audit data/input.csv -o output/audit --trim --dedupe --standardize-headers
wasmtime run --dir ./data::data --dir ./output::output "$wasm" intake data/input.csv -o output/intake --categorical-domains --numeric-ranges
```

Use `explore` for first-pass understanding, `audit` when cleaning choices are
the focus, and `intake` for reusable handoff artifacts. Inspect the generated
manifest or report before summarizing the bundle.

## Workbook Cached-Value Intake

Workbook handling is read-only cached-value intake/export. Start with triage
when the useful table is not obvious:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook triage data/book.xlsx -f json -o output/triage.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook sheets data/book.xlsx -f json -o output/sheets.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook tables data/book.xlsx -f csv -o output/tables.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook regions data/book.xlsx -f json -o output/regions.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook export data/book.xlsx --recommended -o output/recommended.csv
```

Use explicit selectors when the target is known:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook export data/book.xlsx --sheet Sheet1 -o output/sheet.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook export data/book.xlsx --table SalesTable -o output/sales.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook export data/book.xlsx --sheet-index 2 --region B4:F20 -o output/region.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" xlsx data/book.xlsx --list-tables -f json -o output/xlsx-tables.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" ods data/book.ods --sheet-index 1 --region A1:D20 -o output/ods-region.csv
```

Many normal table commands can read supported workbook inputs directly. Use
the same selector that triage or inventory identified:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/book.xlsx --recommended -f json -o output/recommended-profile.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" preview data/book.xlsx --table SalesTable -n 10 --columns 8 -f csv -o output/table-preview.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" schema infer data/book.xlsx --sheet-index 2 --region B4:F20 -f rules -o output/region-rules.json
```

Read `triage.json` for the recommended selector and reason. Native XLSX table
selection follows saved table refs. Cached-region detection is a deterministic
value-based aid; it does not use styling, merged-cell layout, hidden rows, or
formula recalculation. After export, run normal CSV recipes on the exported
file if a separate derivative CSV is easier to inspect.

Formulas are not recalculated, macros/scripts are not executed, styling is not
preserved, and native workbook charts are not rendered. Legacy `.xls` files are
outside scope; use a CSV, `.xlsx`, or `.ods` export instead.

## Visual Review

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" viz data/input.csv --histogram amount --bins 30 -o output/histogram.html
wasmtime run --dir ./data::data --dir ./output::output "$wasm" viz data/input.csv --scatter height weight --color species -o output/scatter.html
wasmtime run --dir ./data::data --dir ./output::output "$wasm" dashboard data/input.csv --max-plots 6 -o output/dashboard.html
```

Dashboard config files can select plot types:

```json
{
  "title": "Review Dashboard",
  "plots": [
    { "type": "histogram", "column": "amount" },
    { "type": "box", "column": "amount", "group_by": "region" },
    { "type": "scatter", "column": "cost", "group_by": "revenue" },
    { "type": "bar", "column": "category" },
    { "type": "correlation" }
  ]
}
```

Supported dashboard plot types are `histogram`, `box`, `scatter`, `bar`, and
`correlation`. HTML outputs are review artifacts; do not promise static image
or PDF export.

## Troubleshooting

- If the module cannot open a file, check that the guest path starts under a
  preopened directory such as `data/` or `output/`.
- Wasmer is not a recommended fallback for these examples. Its `--mapdir`
  behavior has varied across environments; use it only after local smoke
  testing confirms the exact artifact and directory mapping.
- If a column is not found, run `columns` or standardize headers with `clean`.
- If command help prints `s4s-csv` or `s4s_csv`, read it as the upstream
  shorthand for `skills_csv`; this package exposes the artifact as `csv.wasm`.
- If a workbook table is ambiguous, run `workbook triage`; then use
  `--recommended` or choose an exact `--sheet`, one-based `--sheet-index`,
  native XLSX `--table`, or cached `--region`.
- If a chart is empty, inspect `missing`, `numeric`, and `categorical` outputs
  before changing the chart command.
