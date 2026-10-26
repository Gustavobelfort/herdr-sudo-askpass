# Changelog

## Unreleased

## 0.1.1

- Fix the Nix package: files were copied under store-hashed names, so
  `askpass.sh` was missing from it. herdr-installed copies were unaffected.

## 0.1.0

- Ask for the sudo password in a herdr pane split below the agent.
- Ctrl+C in the pane refuses; sudo fails immediately.
- 5 minute timeout (`HERDR_SUDO_ASKPASS_TIMEOUT`).
- Graphical fallback outside herdr: `HERDR_SUDO_ASKPASS_FALLBACK`, zenity,
  kdialog, or a macOS dialog.
- Stable launcher at `$HERDR_PLUGIN_STATE_DIR/askpass` that survives updates.
