#!/usr/bin/env bash
# Exercises askpass.sh and prompt.sh against a fake herdr: the fake runs the
# prompt pane's command in the background with scripted keyboard input, which
# is what herdr does with a real terminal.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; fail=1; fi; }

cat >"$tmp/herdr" <<'FAKE'
#!/usr/bin/env bash
# fake herdr: `plugin pane open ... --env K=V` runs prompt.sh with $FAKE_INPUT
[ "$1 $2 $3" = "plugin pane open" ] || exit 0
envs=(); while [ $# -gt 0 ]; do [ "$1" = --env ] && envs+=("$2"); shift; done
[ "${FAKE_INPUT-}" = none ] && exit 0
( cd "$ROOT" && env "${envs[@]}" bash prompt.sh <<<"$FAKE_INPUT" >/dev/null 2>&1 ) &
FAKE
chmod +x "$tmp/herdr"
run() { HERDR_BIN_PATH="$tmp/herdr" ROOT="$root" HERDR_PANE_ID=w1:p1 XDG_RUNTIME_DIR="$tmp" \
  HERDR_SUDO_ASKPASS_TIMEOUT=2 FAKE_INPUT="$1" bash "$root/askpass.sh" "pw: " </dev/null; }

out=$(run 'hunter2'); check "password is returned" "$out" "hunter2"
out=$(run 'pass with spaces '); check "spaces survive" "$out" "pass with spaces "
out=$(run ''); rc=$?; check "empty input still answers" "$rc:$out" "0:"
out=$(run none); rc=$?; check "no answer times out" "$rc" "1"
out=$(HERDR_SUDO_ASKPASS_FALLBACK="$(type -P echo)" HERDR_PANE_ID='' bash "$root/askpass.sh" "x"); \
  check "outside herdr uses fallback" "$out" "x"
check "no fifo left behind" "$(find "$tmp" -name 'herdr-sudo-askpass.*' | wc -l)" "0"
exit $fail
