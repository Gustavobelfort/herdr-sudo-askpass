#!/usr/bin/env bash
# The pane askpass.sh opens. Reads the password with echo off and replies
# through the FIFO askpass.sh is waiting on; the pane closes when this exits.
set -u
reply="${HERDR_SUDO_ASKPASS_REPLY:?not started by askpass.sh}"

answer() { [ -p "$reply" ] && printf '%s\n' "$1" >"$reply"; exit 0; }
# Ctrl+C, or closing the pane, cancels instead of leaving sudo to time out.
trap 'echo; answer cancel' INT HUP TERM

printf 'An agent wants root for:\n  %s\n\n' "${HERDR_SUDO_ASKPASS_CALLER:-sudo}"
printf '(Ctrl+C to refuse)\n\n'
IFS= read -rs -p "${HERDR_SUDO_ASKPASS_PROMPT:-[sudo] password: }" pw || answer cancel
echo
answer "ok $pw"
