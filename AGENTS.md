# Agent guide

A herdr plugin: when a coding agent runs `sudo` without a terminal, the
password prompt opens as a herdr pane beside it. Three small scripts; read all
of them before changing any.

## Files

| File | Role |
| --- | --- |
| `herdr-plugin.toml` | manifest: startup hook, `setup` action, `prompt` pane |
| `askpass.sh` | what `SUDO_ASKPASS` runs; opens the pane, waits on a FIFO, prints the password |
| `prompt.sh` | runs inside the pane; reads the password with echo off, replies through the FIFO |
| `install-shim.sh` | writes the stable launcher `$HERDR_PLUGIN_STATE_DIR/askpass` |
| `test/test.sh` | end-to-end tests against a fake `herdr`; no server needed |

The design and its trade-offs are in `docs/design.md`.

## Checks

```sh
nix develop      # shellcheck, shfmt, zizmor, make
make check       # lint + format check + tests: what CI runs
make fmt         # rewrite formatting
nix flake check  # the same checks in a sandbox
```

Run `make check` before finishing. Add a case to `test/test.sh` for any
behaviour change; the fake `herdr` runs `prompt.sh` with scripted input.

## Rules

- **The password never touches disk, argv or the environment.** It moves only
  through the FIFO and stdout. Never log it, echo it, or pass it as an argument
  (argv is world-readable in `ps`). Reviewers will reject changes that do.
- **askpass.sh must always exit.** sudo blocks on it; every path needs an
  answer, a cancel, or the timeout.
- **Portable shell.** bash 3.2 (macOS) and Linux. No GNU-only flags, no
  `/usr/bin/env` assumptions in tests. `install-shim.sh` is POSIX `sh`.
- **No new runtime dependencies** beyond bash, mkfifo, mktemp and ps.
- **Manifest compatibility.** Raising `min_herdr_version` needs a reason in the
  changelog.
- Comments explain why, not what.

## Releasing

Bump `version` in `herdr-plugin.toml`, add a `CHANGELOG.md` entry, tag
`vX.Y.Z`. Users get it with `herdr plugin update`.
