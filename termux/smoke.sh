#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
bin=${1:-target/release/obscura}
"$bin" --version
result=$("$bin" fetch 'data:text/html,<title>Termux test</title>' --eval '1+1')
printf '%s\n' "$result"
printf '%s\n' "$result" | grep -Eq '(^|[^0-9])2([^0-9]|$)'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
"$bin" fetch 'data:text/html,<style>body{background:%23123456}</style>' --screenshot "$tmp/smoke.png"
test -s "$tmp/smoke.png"
