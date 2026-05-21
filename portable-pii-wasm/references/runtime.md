# PII Runtime Setup

Install or select a WASIp1 runtime for the bundled `pii.wasm` artifact. Keep
using explicit directory preopens and guest paths in every runtime.

## Runtime Selection

Try in this order:

1. `wasmtime`
2. `wasmedge`
3. `iwasm`, only after `selftest` or `capabilities` succeeds
4. `pywasm`, only as a slow last resort through `uv run --with pywasm` or an
   already-approved Python environment with `pywasm`

If none are available, stop and report that a compatible WASIp1 runtime is
required. Do not replace the workflow with Python PII libraries, containers,
network PII services, shell parsing, or non-sandboxed file handling.

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
wasm=portable-pii-wasm/assets/pii.wasm
wasmtime run --dir ./data::data --dir ./output::output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

## WasmEdge Fallback

Use WasmEdge when `wasmtime` is unavailable but `wasmedge` exists or can be
installed:

```sh
wasmedge --version
wasmedge --dir data:./data --dir output:./output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

WasmEdge maps directories as `guest:host`, unlike Wasmtime's `host::guest`.

## WAMR/iwasm Conditional Fallback

Use `iwasm` only after a simple command succeeds for this artifact:

```sh
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" selftest --format=json
iwasm --map-dir=data::./data --map-dir=output::./output \
  "$wasm" check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

Some iwasm builds lack WebAssembly features used by an artifact. If `selftest`
or `capabilities` fails, use Wasmtime or WasmEdge instead and report the
runtime incompatibility.

## pywasm Last Resort

Use this only as a Python-hosted WASIp1 fallback. It still runs `pii.wasm`; it
must not become Python PII detection. Expect it to be slower than native
runtimes, and run `selftest` or `capabilities` first to check artifact
compatibility.

Prefer `uv` for an ephemeral package environment:

```sh
uv run --with pywasm python portable-pii-wasm/scripts/run_pywasm.py \
  portable-pii-wasm/assets/pii.wasm selftest --format=json
uv run --with pywasm python portable-pii-wasm/scripts/run_pywasm.py \
  --dir ./data::data --dir ./output::output \
  portable-pii-wasm/assets/pii.wasm \
  check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

If `pywasm` is already available in the selected Python environment:

```sh
python3 -c "import pywasm; print('pywasm ok')"
python3 portable-pii-wasm/scripts/run_pywasm.py \
  --dir ./data::data --dir ./output::output \
  portable-pii-wasm/assets/pii.wasm \
  check data/ticket.txt --preset=customer_support \
  --format=json --report=safe
```

The runner accepts Wasmtime-style `--dir host::guest` mappings and translates
them to pywasm's guest-to-host directory table internally. `check`, `scan`, and
`scan --diff` may exit nonzero when findings are present; read the JSON output
before treating that as a runtime failure.

If package download is blocked by policy, network, or platform support, stop
and ask the user to provide a compatible WASIp1 runtime or an approved Python
environment with `pywasm`.

## Sources

- Wasmtime CLI install: https://docs.wasmtime.dev/cli-install.html
- WasmEdge install: https://wasmedge.org/docs/start/install/
- pywasm package and API: https://pypi.org/project/pywasm/
