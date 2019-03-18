#!/bin/bash
exec 3>&1
exec 4>&2

prefix() {
 local line
 while read line; do printf '%s %-6s %s\n' "$(date)" "$1" "$line"; done
}

stdout=$(mktemp -u)
stderr=$(mktemp -u)
mkfifo "$stdout" "$stderr"
trap 'sleep 0.2; rm -f "$stdout" "$stderr"' EXIT

prefix 'INFO' < "$stdout" >&1 &
prefix 'ERROR' < "$stderr" >&2 &

exec 1>"$stdout"
exec 2>"$stderr"

function log() {
  echo $@
}

function error() {
  echo $@ 1>&2
}
