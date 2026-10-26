# Design

## The problem

`sudo` reads the password from the controlling terminal. A coding agent's
shell tool has none, so `sudo` fails. `sudo` falls back to the program named by
`SUDO_ASKPASS` when there is no terminal (or with `-A`) and reads the password
from its stdout.

Graphical askpass helpers draw on the machine's display. With herdr that is the
wrong place: you may be attached over SSH or from a phone, while the herdr
server (and so the agent) inherited the desktop's `DISPLAY`. The dialog opens
on a screen nobody is looking at.

## The approach

The agent already runs in a herdr pane, and herdr puts `HERDR_PANE_ID` in its
environment. `askpass.sh` uses it to open a plugin pane split below the agent,
which is visible wherever the session is attached.

```
sudo ──runs──▶ askpass.sh ──herdr plugin pane open──▶ prompt.sh (in a pane)
   ▲               │  waits on FIFO (read -t)              │ read -rs
   └── stdout ─────┘◀──────────── "ok <password>" ─────────┘
```

## Decisions

- **FIFO, not a file or argv.** A FIFO in a private `mktemp -d` directory
  (0600) holds nothing at rest. argv and environment are readable by other
  processes; a regular file would need shredding.
- **askpass opens the FIFO read-write.** Opening a FIFO read-only blocks until
  a writer appears, and the timeout could never fire. With `<>` the open is
  immediate and `read -t` bounds the wait.
- **`ok `/`cancel` framing.** Distinguishes "the user typed an empty password"
  from "the user refused", so Ctrl+C makes sudo stop at once instead of
  retrying three times.
- **Stable shim in the state dir.** `herdr plugin install` uses a new
  directory per update. `SUDO_ASKPASS` points at `$HERDR_PLUGIN_STATE_DIR/askpass`,
  rewritten by the startup hook, so updates never break the configured path.
- **Always the pane inside herdr.** There is no reliable way, from inside the
  pane, to tell whether the human is at the machine or remote, so the plugin
  does not try.

## Threat model

The plugin runs as the user and adds no privilege. Anything running as the
user can already drive herdr panes, read the user's terminals, and wrap `sudo`.
The goal is only to not make things worse:

- the password is not persisted, logged, or exposed through argv/env;
- the prompt shows the requesting command so the human can refuse;
- an unanswered prompt times out rather than leaving sudo pending.

Out of scope: a malicious process running as the same user. It could spoof the
prompt pane just as it could spoof a terminal. Prefer `sudo` rules that limit
what agents may run.
