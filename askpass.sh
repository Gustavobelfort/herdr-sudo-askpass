#!/usr/bin/env bash
# SUDO_ASKPASS helper. sudo runs this without a terminal and reads the password
# from stdout. Inside a herdr pane the prompt opens as a pane beside the caller,
# so it reaches wherever the session is attached; anywhere else it hands off to
# a graphical fallback.
set -u

prompt="${1:-[sudo] password: }"
plugin_id="${HERDR_SUDO_ASKPASS_PLUGIN_ID:-sudo-askpass}"
timeout="${HERDR_SUDO_ASKPASS_TIMEOUT:-300}"
herdr="${HERDR_BIN_PATH:-herdr}"
# After `herdr update` the server-injected path can name a deleted binary.
[ -x "$herdr" ] || herdr="$(command -v herdr || true)"

fallback() {
  if [ -n "${HERDR_SUDO_ASKPASS_FALLBACK:-}" ]; then
    exec "$HERDR_SUDO_ASKPASS_FALLBACK" "$prompt"
  fi
  if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    command -v zenity >/dev/null && exec zenity --password --title="$prompt"
    command -v kdialog >/dev/null && exec kdialog --password "$prompt"
  fi
  if [ "$(uname)" = Darwin ]; then
    exec osascript -e "text returned of (display dialog \"$prompt\" default answer \"\" with hidden answer)"
  fi
  echo "herdr-sudo-askpass: not in a herdr pane and no graphical prompt available" >&2
  exit 1
}

[ -n "${HERDR_PANE_ID:-}" ] && [ -n "$herdr" ] || fallback

dir="$(mktemp -d "${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdr-sudo-askpass.XXXXXX")" || exit 1
trap 'rm -rf "$dir"' EXIT
mkfifo -m 600 "$dir/reply" || exit 1
# Opened read-write so neither side blocks on open, and `read -t` can time out
# even if the pane never answers. The pane writes "ok <password>" or "cancel".
exec 3<>"$dir/reply"

caller="$(ps -o args= -p "$PPID" 2>/dev/null | cut -c1-200)"

"$herdr" plugin pane open --plugin "$plugin_id" --entrypoint prompt \
  --placement split --target-pane "$HERDR_PANE_ID" --direction down --focus \
  --env "HERDR_SUDO_ASKPASS_REPLY=$dir/reply" \
  --env "HERDR_SUDO_ASKPASS_PROMPT=$prompt" \
  --env "HERDR_SUDO_ASKPASS_CALLER=${caller:-sudo}" >/dev/null || fallback
"$herdr" notification show "sudo password needed" --body "${caller:-sudo}" \
  --sound request >/dev/null 2>&1 || true

IFS= read -r -t "$timeout" reply <&3 || exit 1
case "$reply" in
  "ok "*) printf '%s\n' "${reply#ok }" ;;
  *) exit 1 ;; # cancelled: sudo gives up instead of retrying an empty password
esac
