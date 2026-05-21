# PII Runtime Setup

Install or select a WASIp1 runtime for the bundled `pii.wasm` artifact. Keep
using explicit directory preopens and guest paths in every runtime.

## Runtime Selection

Try in this order:

1. `wasmtime`
2. `wasmedge`
3. `iwasm`, only after `selftest` or `capabilities` succeeds

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

## Python-Hosted Runtime Experiments

Do not use Python-hosted runtimes as normal fallbacks. They add a package
supply-chain surface and weaken the portable-Wasm safety signal for this
skill.

If a user explicitly approves a local `pywasm` experiment, keep it external to
the skill package. The experiment must still run `pii.wasm`, bind WASIp1
preopens equivalent to the commands above, and pass `selftest` or
`capabilities` before scanning user files. Do not generate or install a Python
PII detector as a substitute. If the experiment fails, stop and ask for
Wasmtime, WasmEdge, or a compatible iwasm build.

## Sources

- Wasmtime CLI install: https://docs.wasmtime.dev/cli-install.html
- WasmEdge install: https://wasmedge.org/docs/start/install/
- pywasm package, for explicit troubleshooting experiments only:
  https://pypi.org/project/pywasm/
