# Agent Guidelines

This repository packages user-facing portable skills. Keep the public docs
focused on what a user can safely do with the bundled skill artifacts, not how
the artifacts are implemented.

## Product Boundary

- Treat bundled `.wasm` files as black-box tool artifacts.
- Explain the supported command surface through `--help`, examples, and clear
  safety boundaries.
- Do not describe internal source layout, language choices, parity ledgers,
  upstream implementation details, or maintainer workflows in user-facing docs.
- Do not disclose local environment details in public docs or user-facing
  examples. Avoid machine-specific absolute paths, usernames, home directories,
  temporary checkout paths, shell history, or private repository locations.
- Avoid marketing the tools as replacements for full spreadsheet applications,
  notebook environments, native renderers, or human review.

## Safety Framing

- Emphasize sandboxed first-pass file work.
- Explain explicit WASI directory preopens with `wasmtime run --dir host::guest`.
- Prefer examples that separate input and output directories.
- Make it clear that generated reports and cleaned files are derivative review
  artifacts.
- Do not imply ambient filesystem access, automatic trust, or hidden network
  access.

## Skill Content

- Keep `SKILL.md` short enough for an agent to use directly.
- Prefer concrete commands over abstract claims.
- Document feature boundaries directly beside the feature when a command has a
  limited scope.
- Keep examples portable and deterministic.
- Do not require Python, pandas, Plotly, LibreOffice, Node, shell CSV pipelines,
  or native renderers for normal skill use.

## Artifact Updates

- When replacing a bundled `.wasm`, verify at least:
  - `wasmtime run <artifact> --help`
  - one read-only inspection command with an explicit `--dir`
  - one command that writes to an explicitly preopened output directory
- Update the skill docs if the command surface or boundaries changed.
- Keep `NOTICE` and license attributions accurate when bundled artifacts change.

## Git Discipline

- Use conventional commits for accepted changes.
- Keep docs, artifact updates, and license changes in separate commits when
  practical.
- Do not push changes until the maintainer has reviewed and approved them.
