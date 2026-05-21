# CSV Runtime Setup

Install or select a WASIp1 runtime for the bundled `csv.wasm` artifact. Keep
using explicit directory preopens and guest paths in every runtime.

## Runtime Selection

Try in this order:

1. `wasmtime`
2. `wasmedge`
3. `iwasm`, only after a simple artifact check succeeds
4. `pywasm`, only as a slow last resort through `uv run --with pywasm` or an
   already-approved Python environment with `pywasm`

If none are available, stop and report that a compatible WASIp1 runtime is
required. Do not replace the workflow with Python CSV parsing, pandas,
LibreOffice, spreadsheet apps, shell CSV pipelines, containers, or
non-sandboxed parsing.

## Install Or Select Wasmtime

Prefer an existing `wasmtime` binary:

```sh
command -v wasmtime
wasmtime -V
```

If it is missing, use an environment-appropriate install method and then verify
`wasmtime -V`.

Official options include:

- Linux/macOS installer: `curl https://wasmtime.dev/install.sh -sSf | bash`
- precompiled release archives when scripts are not allowed
- Cargo: `cargo install wasmtime-cli`

Use the normal skill command after installation:

```sh
wasm=pure-wasm-csv-skills/assets/csv.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" profile data/input.csv -f json -o output/profile.json
```

## WasmEdge Fallback

Use WasmEdge when `wasmtime` is unavailable but `wasmedge` exists or can be
installed:

```sh
wasmedge --version
wasmedge --dir data:./data --dir output:./output \
  "$wasm" profile data/input.csv -f json -o output/profile.json
```

WasmEdge maps directories as `guest:host`, unlike Wasmtime's `host::guest`.

## WAMR/iwasm Conditional Fallback

Use `iwasm` only after a simple command succeeds for this artifact:

```sh
iwasm --map-dir=data::./data --map-dir=output::./output "$wasm" --help
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" profile data/input.csv -f json -o output/profile.json
```

Some iwasm builds lack WebAssembly features used by an artifact. If the check
fails, use Wasmtime or WasmEdge instead and report the runtime incompatibility.

## pywasm Last Resort

Use this only as a Python-hosted WASIp1 fallback. It still runs `csv.wasm`; it
must not become Python CSV parsing. Expect it to be slower than native
runtimes, and run `--help` first to check artifact compatibility.

Prefer `uv` for an ephemeral package environment:

```sh
uv run --with pywasm python pure-wasm-csv-skills/scripts/run_pywasm.py \
  pure-wasm-csv-skills/assets/csv.wasm --help
uv run --with pywasm python pure-wasm-csv-skills/scripts/run_pywasm.py \
  --dir ./data::data --dir ./output::output \
  pure-wasm-csv-skills/assets/csv.wasm \
  profile data/input.csv -f json -o output/profile.json
```

If `pywasm` is already available in the selected Python environment:

```sh
python3 -c "import pywasm; print('pywasm ok')"
python3 pure-wasm-csv-skills/scripts/run_pywasm.py \
  --dir ./data::data --dir ./output::output \
  pure-wasm-csv-skills/assets/csv.wasm \
  profile data/input.csv -f json -o output/profile.json
```

The runner accepts Wasmtime-style `--dir host::guest` mappings and translates
them to pywasm's guest-to-host directory table internally.

If package download is blocked by policy, network, or platform support, stop
and ask the user to provide a compatible WASIp1 runtime or an approved Python
environment with `pywasm`.

## Sources

- Wasmtime CLI install: https://docs.wasmtime.dev/cli-install.html
- WasmEdge install: https://wasmedge.org/docs/start/install/
- pywasm package and API: https://pypi.org/project/pywasm/
