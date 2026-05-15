# Portable Skills

Portable Skills packages small, sandboxed Wasm tools for safe first-pass work
with local files.

The goal is simple: when you receive a data file that you do not fully trust
yet, inspect it in a constrained environment first. A skill can read only the
directories you explicitly allow, write only to the output locations you provide,
and produce derivative reports you can review before moving the data into
larger tools or workflows.

## Included Skills

### `pure-wasm-csv-skills`

Use the bundled `s4s-csv.wasm` tool to inspect, clean, validate, summarize, and
visualize tabular data.

It is useful for:

- checking the shape, columns, missing values, and basic distributions in a
  CSV/TSV file;
- creating cleaned derivative CSV files without changing the original input;
- generating profile, audit, intake, schema, and quality reports;
- exporting supported spreadsheet inputs into CSV for safer inspection;
- producing portable HTML chart and dashboard artifacts.

## Safety Model

Portable Skills are designed around explicit access:

- run the Wasm tool with a runtime such as `wasmtime`;
- grant file access with explicit `--dir host::guest` preopens;
- keep input and output directories separate when possible;
- treat generated reports as review artifacts before trusting or importing the
  source data elsewhere.

The Wasm artifact is the supported tool surface. Use the built-in command help
to discover what the packaged skill can do:

```sh
wasm=pure-wasm-csv-skills/assets/s4s-csv.wasm
wasmtime run "$wasm" --help
wasmtime run "$wasm" help intake
```

## Artifact Provenance

The bundled Wasm is included so the skill works immediately after checkout.
Version and checksum metadata live beside the artifact:

- `pure-wasm-csv-skills/assets/s4s-csv.version`
- `pure-wasm-csv-skills/assets/s4s-csv.wasm.sha256`

Verify the bundled artifact with:

```sh
shasum -a 256 -c pure-wasm-csv-skills/assets/s4s-csv.wasm.sha256
```

Future versions may also publish the Wasm as a GitHub Release asset, but the
bundled artifact keeps this skill usable in restricted environments.

## Example

Inspect a file without granting access to the rest of your filesystem:

```sh
wasm=pure-wasm-csv-skills/assets/s4s-csv.wasm
wasmtime run --dir ./data::data "$wasm" file-info data/input.csv -f text
wasmtime run --dir ./data::data "$wasm" missing data/input.csv -f csv
```

Create a first-pass intake bundle in an existing output directory:

```sh
mkdir -p out
wasmtime run --dir ./data::data --dir ./out::out "$wasm" intake data/input.csv -o out/intake --trim --drop-empty-rows --dedupe --standardize-headers
```

## Boundary

These skills are for portable, sandboxed first-pass file work. They do not try
to replace full spreadsheet applications, notebook environments, native chart
renderers, or domain-specific review by a human analyst.
