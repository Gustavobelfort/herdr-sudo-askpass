#!/bin/sh
# Writes $HERDR_PLUGIN_STATE_DIR/askpass, a launcher that survives plugin
# updates, and with --notify shows where it is. Point SUDO_ASKPASS at it.
set -eu
shim="$HERDR_PLUGIN_STATE_DIR/askpass"
mkdir -p "$HERDR_PLUGIN_STATE_DIR"
cat >"$shim.tmp" <<SHIM
#!/bin/sh
HERDR_SUDO_ASKPASS_PLUGIN_ID='$HERDR_PLUGIN_ID' exec bash '$HERDR_PLUGIN_ROOT/askpass.sh' "\$@"
SHIM
chmod 755 "$shim.tmp"
mv "$shim.tmp" "$shim"
if [ "${1:-}" = --notify ]; then
  "${HERDR_BIN_PATH:-herdr}" notification show "sudo askpass" \
    --body "export SUDO_ASKPASS=$shim" >/dev/null
  echo "export SUDO_ASKPASS=$shim"
fi
