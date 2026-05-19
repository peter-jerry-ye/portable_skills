# CSV Usage Reference

Use this reference when the top-level skill file is not detailed enough. The
CLI help remains the source of truth for exact flags:

```sh
wasmtime run pure-wasm-csv-skills/assets/csv.wasm --help
wasmtime run pure-wasm-csv-skills/assets/csv.wasm help profile
```

Any WASIp1-capable runtime is sufficient. These examples suggest `wasmtime`
because its directory preopen syntax is explicit.

## Runtime Pattern

Use guest paths inside the module and map host directories explicitly:

```sh
mkdir -p data output
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" profile data/input.csv \
  -f json -o output/profile.json
```

For troubleshooting, keep `data` and `output` directly under the current
directory until the path mapping is clear.

## Inspection Commands

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" preview data/input.csv -n 10 --columns 8 -f csv -o output/preview.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" file-info data/input.csv -f json -o output/file-info.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" overview data/input.csv -f csv -o output/overview.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" columns data/input.csv -f csv -o output/columns.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" missing data/input.csv -f csv -o output/missing.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" profile data/input.csv -f html -o output/profile.html
```

Use JSON or CSV when an agent will inspect the result. Use HTML for human review
reports.

## Analysis Commands

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" numeric data/input.csv -f csv -o output/numeric.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" categorical data/input.csv -f csv -o output/categorical.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" correlation data/input.csv --columns score,cost -f csv -o output/correlation.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" crosstab data/input.csv --row species --column island -f csv -o output/crosstab.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" groupby data/input.csv --by species --mean body_mass_g,flipper_length_mm -f csv -o output/grouped.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" summary data/input.csv -o output/summary.tsv --delimiter tsv
```

## Cleaning and Validation

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" clean data/raw.csv -o output/clean.csv --trim --drop-empty-rows --normalize-empty --dedupe --standardize-headers --report output/clean-report.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" schema infer output/clean.csv -f rules -o output/rules.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" validate output/clean.csv --rules output/rules.json -f json -o output/validation.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" quality output/clean.csv -f csv -o output/quality.csv --fail-on-issues
```

`clean` creates a derivative CSV. Keep the report with the cleaned file when
the user needs to review what changed.

## Bundles

`explore`, `audit`, and `intake` write multiple artifacts. Create the output
directory first:

```sh
mkdir -p output/explore output/audit output/intake
wasmtime run --dir ./data::data --dir ./output::output "$wasm" explore data/input.csv -o output/explore --max-plots 6
wasmtime run --dir ./data::data --dir ./output::output "$wasm" audit data/input.csv -o output/audit --trim --dedupe --standardize-headers
wasmtime run --dir ./data::data --dir ./output::output "$wasm" intake data/input.csv -o output/intake --categorical-domains --numeric-ranges
```

Use `explore` for first-pass understanding, `audit` when cleaning changes are
the focus, and `intake` for reusable handoff artifacts.

## Workbook Cached-Value Intake

Workbook handling is read-only cached-value intake:

```sh
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook sheets data/book.xlsx -f json -o output/sheets.json
wasmtime run --dir ./data::data --dir ./output::output "$wasm" workbook export data/book.xlsx --sheet Sheet1 -o output/sheet.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" xlsx data/book.xlsx --list-sheets -f csv -o output/sheets.csv
wasmtime run --dir ./data::data --dir ./output::output "$wasm" ods data/book.ods --sheet-index 1 -o output/sheet.csv
```

Formulas are not recalculated, macros/scripts are not executed, styling is not
preserved, and native workbook charts are not rendered.

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
`correlation`.

## Troubleshooting

- If the module cannot open a file, check that the guest path starts under a
  preopened directory such as `data/` or `output/`.
- If a column is not found, run `columns` or standardize headers with `clean`.
- If a workbook sheet is ambiguous, run `workbook sheets` and select by exact
  sheet name or one-based `--sheet-index`.
- If a chart is empty, inspect `missing`, `numeric`, and `categorical` outputs
  before changing the chart command.
