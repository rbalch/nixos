#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo/users/ryan/configs/grok-bot.sh"
test_root="$(mktemp -d)"
trap 'rm -r -- "$test_root"' EXIT
mkdir "$test_root/bin"
ln -s "$repo/tests/fixtures/appimage-run" "$test_root/bin/appimage-run"
export PATH="$test_root/bin:$PATH"
export XDG_DATA_HOME="$test_root/data"
export TEST_PAYLOAD="$test_root/release"
export TEST_LOG="$test_root/downloads"
printf 'new release\n' >"$TEST_PAYLOAD"
hash="$(sha256sum "$TEST_PAYLOAD" | cut -d ' ' -f 1)"
export TEST_FEED="$(jq -cn --arg hash "$hash" \
    '{version:"0.58.0",url:"https://downloads.cursor.com/grokbot/stable/abc123/linux/x64/Grok_Bot_0.58.0.AppImage",sha256hash:$hash}')"

curl() {
    local arg output=''
    for arg in "$@"; do
        if [ "$output" = next ]; then output="$arg"; break; fi
        if [ "$arg" = -o ]; then output=next; fi
    done
    if [ -z "$output" ]; then
        if [ "${TEST_FEED_FAIL:-}" = yes ]; then return 22; fi
        printf '%s\n' "$TEST_FEED"
    else
        if [ "${TEST_DOWNLOAD_FAIL:-}" = yes ]; then return 22; fi
        printf 'x' >>"$TEST_LOG"
        if [ "${TEST_DOWNLOAD_DELAY:-}" = yes ]; then sleep 1; fi
        cp -- "$TEST_PAYLOAD" "$output"
    fi
}
export -f curl

app="$XDG_DATA_HOME/grok-bot/Grok_Bot.AppImage"
previous="$XDG_DATA_HOME/grok-bot/Grok_Bot.previous.AppImage"

# Concurrent first launches must leave a single verified image.
export TEST_DOWNLOAD_DELAY=yes
bash "$script" >"$test_root/first.log" & first_pid=$!
bash "$script" >"$test_root/second.log" & second_pid=$!
wait "$first_pid"
wait "$second_pid"
unset TEST_DOWNLOAD_DELAY
test "$(wc -c <"$TEST_LOG")" -eq 1
cmp "$TEST_PAYLOAD" "$app"

# A current install does not need a sidecar or another download.
bash "$script" update >"$test_root/current.log"
test "$(wc -c <"$TEST_LOG")" -eq 1

# Upgrade an older image with no version file and keep its last good copy.
printf 'old release\n' >"$app"
bash "$script" update >"$test_root/upgrade.log"
cmp "$TEST_PAYLOAD" "$app"
test "$(cat "$previous")" = 'old release'

# Feed, download, and hash failures must preserve the current app and backup.
export TEST_FEED='{"bad":"release"}'
if bash "$script" update >"$test_root/bad-feed.log" 2>&1; then exit 1; fi
cmp "$TEST_PAYLOAD" "$app"
test "$(cat "$previous")" = 'old release'

export TEST_FEED='not JSON'
if bash "$script" update >"$test_root/bad-json.log" 2>&1; then exit 1; fi
cmp "$TEST_PAYLOAD" "$app"
test "$(cat "$previous")" = 'old release'

export TEST_FEED="$(jq -cn --arg hash "$hash" \
    '{version:"0.58.0",url:"https://downloads.cursor.com/grokbot/stable/abc123/linux/x64/Grok_Bot_0.58.0.AppImage",sha256hash:$hash}')"
printf 'old release\n' >"$app"
export TEST_DOWNLOAD_FAIL=yes
if bash "$script" update >"$test_root/download-fail.log" 2>&1; then exit 1; fi
unset TEST_DOWNLOAD_FAIL
test "$(cat "$app")" = 'old release'
test "$(cat "$previous")" = 'old release'

printf 'wrong bytes\n' >"$TEST_PAYLOAD"
if bash "$script" update >"$test_root/hash-fail.log" 2>&1; then exit 1; fi
test "$(cat "$app")" = 'old release'
test "$(cat "$previous")" = 'old release'

printf 'new release\n' >"$TEST_PAYLOAD"
export TEST_FEED_FAIL=yes
if bash "$script" update >"$test_root/feed-fail.log" 2>&1; then exit 1; fi
unset TEST_FEED_FAIL
test "$(cat "$app")" = 'old release'

export TEST_APP="$app"
mv() {
    if [ "${TEST_REPLACE_FAIL:-}" = yes ] && [ "${*: -1}" = "$TEST_APP" ]; then
        return 1
    fi
    command mv "$@"
}
export -f mv
export TEST_REPLACE_FAIL=yes
if bash "$script" update >"$test_root/replace-fail.log" 2>&1; then exit 1; fi
test "$(cat "$app")" = 'old release'
test "$(cat "$previous")" = 'old release'

printf 'Grok Bot update tests passed\n'
