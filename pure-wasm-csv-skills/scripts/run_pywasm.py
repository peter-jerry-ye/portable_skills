#!/usr/bin/env python3
"""Run a WASIp1 command module with pywasm.

This is a last-resort launcher for environments where native WASIp1 runtimes
are not available but a Python environment can use `pywasm`. It does not parse
CSV data; it only runs the bundled Wasm artifact with explicit WASI preopens.
"""

import argparse
import sys
from pathlib import Path


def split_preopen(value):
    if "::" not in value:
        raise argparse.ArgumentTypeError("preopen must be host::guest")
    host, guest = value.split("::", 1)
    if not host or not guest:
        raise argparse.ArgumentTypeError("preopen must be host::guest")
    return host, guest


def wasi_exit_code(exc):
    if len(exc.args) == 2 and exc.args[0] is SystemExit:
        return int(exc.args[1])
    return None


def main():
    parser = argparse.ArgumentParser(description="Run a WASIp1 module through pywasm")
    parser.add_argument(
        "--dir",
        action="append",
        default=[],
        type=split_preopen,
        metavar="HOST::GUEST",
        help="Preopen HOST as GUEST, matching wasmtime CLI host::guest syntax",
    )
    parser.add_argument("wasm", help="Path to the .wasm command module")
    parser.add_argument(
        "guest_args",
        nargs=argparse.REMAINDER,
        help="Arguments passed to the module",
    )
    args = parser.parse_args()

    guest_args = args.guest_args
    if guest_args and guest_args[0] == "--":
        guest_args = guest_args[1:]

    try:
        import pywasm
    except ImportError:
        print(
            "pywasm is not installed. Use a native WASIp1 runtime first, or run "
            "this launcher through `uv run --with pywasm` after package download "
            "is approved.",
            file=sys.stderr,
        )
        return 127

    wasm_path = Path(args.wasm)
    guest_dirs = {guest: host for host, guest in args.dir}

    runtime = pywasm.Runtime()
    wasi = pywasm.wasi.Preview1([wasm_path.name, *guest_args], guest_dirs, {})
    wasi.bind(runtime)
    module = runtime.instance_from_file(str(wasm_path))

    try:
        runtime.invocate(module, "_start", [])
    except Exception as exc:
        exit_code = wasi_exit_code(exc)
        if exit_code is not None:
            return exit_code
        raise

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
