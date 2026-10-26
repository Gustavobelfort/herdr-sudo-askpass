# herdr-sudo-askpass

A [herdr](https://herdr.dev) plugin. When a coding agent runs `sudo`, the
password prompt opens as a pane right beside the agent:

```
┌ claude ─────────────────────────────────────┐
│ ● Bash(sudo nixos-rebuild switch)           │
├ sudo password ──────────────────────────────┤
│ An agent wants root for:                    │
│   sudo nixos-rebuild switch                 │
│                                             │
│ (Ctrl+C to refuse)                          │
│                                             │
│ [sudo] password for you: ▌                  │
└─────────────────────────────────────────────┘
```

## Why

Agents run commands without a terminal, so `sudo` cannot ask for a password
and fails. The usual fix, a graphical `SUDO_ASKPASS` like zenity, opens on the
machine's own screen, which you cannot see when you are attached over SSH or
from your phone. A herdr pane goes wherever your session is.

## Install

```sh
herdr plugin install Gustavobelfort/herdr-sudo-askpass
```

Then point `SUDO_ASKPASS` at the launcher the plugin keeps in its state
directory. Run the **sudo askpass: show setup** action to print the exact path,
or use the default:

```sh
export SUDO_ASKPASS="$HOME/.local/state/herdr/plugins/sudo-askpass/askpass"
```

Put that where your agent will see it. For Claude Code, add it to `env` in
`~/.claude/settings.json`; a shell profile only reaches agents started from a
login shell.

`sudo` only consults `SUDO_ASKPASS` when it has no terminal, or with `-A`, so
your normal terminal prompt is unchanged. Tell your agent to use `sudo -A` to
be explicit.

## Behaviour

- Inside herdr: a split opens below the calling pane and takes focus, and herdr
  shows a notification. Type the password (no echo) and the pane closes.
  **Ctrl+C refuses**, and sudo fails immediately.
- No answer within 5 minutes: sudo fails, so an agent is never stuck forever.
- Outside herdr: falls back to `$HERDR_SUDO_ASKPASS_FALLBACK`, then `zenity`,
  `kdialog`, or a macOS dialog.

## Configuration

Environment variables, set alongside `SUDO_ASKPASS`:

| Variable | Default | |
| --- | --- | --- |
| `HERDR_SUDO_ASKPASS_TIMEOUT` | `300` | seconds to wait for an answer |
| `HERDR_SUDO_ASKPASS_FALLBACK` | | askpass program to use outside herdr |

## Security

The password travels from the prompt pane to the waiting helper through a FIFO
in a fresh `mktemp -d` directory under `$XDG_RUNTIME_DIR`, mode 0600, removed
when the helper exits. It is never written to disk or passed on a command line.

Any process running as you can already open herdr panes and type into them, so
this adds no new trust boundary. It does mean an agent can _ask_ for root:
read the command shown in the pane before typing.

## Requirements

herdr 0.9.0 or newer, `bash`, and `mkfifo`. Linux and macOS.

## Development

```sh
herdr plugin link .   # use your checkout
test/test.sh          # runs against a fake herdr, no server needed
```

## License

MIT
