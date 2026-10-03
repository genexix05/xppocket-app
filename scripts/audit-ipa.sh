#!/usr/bin/env bash
# Verify a Release iphoneos XP Pocket.app or unsigned .ipa before publishing.
#
# Usage:
#   scripts/audit-ipa.sh path/to/XP\ Pocket.app
#   scripts/audit-ipa.sh [--version X.Y.Z] path/to/Empo-unsigned.ipa
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_VERSION=""
INPUT=""

fail() {
    echo "error: $*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 ]] || fail "--version requires a value"
            EXPECTED_VERSION="$2"
            shift 2
            ;;
        -h | --help)
            echo "usage: $0 [--version X.Y.Z] <XP Pocket.app | *.ipa>"
            exit 0
            ;;
        *)
            [[ -z "$INPUT" ]] || fail "unexpected argument: $1"
            INPUT="$1"
            shift
            ;;
    esac
done

[[ -n "$INPUT" ]] || fail "missing path to XP Pocket.app or .ipa"

TMPDIR=""
cleanup() {
    if [[ -n "$TMPDIR" && -d "$TMPDIR" ]]; then
        rm -rf "$TMPDIR"
    fi
}
trap cleanup EXIT

APP=""
case "$INPUT" in
    *.ipa)
        [[ -f "$INPUT" ]] || fail "ipa not found: $INPUT"
        TMPDIR=$(mktemp -d)
        unzip -q "$INPUT" -d "$TMPDIR"
        APP="$(find "$TMPDIR/Payload" -maxdepth 1 -name '*.app' -print -quit)"
        ;;
    *.app)
        APP="$INPUT"
        ;;
    *)
        fail "expected .app bundle or .ipa, got: $INPUT"
        ;;
esac

[[ -n "$APP" && -d "$APP" ]] || fail "app bundle not found in $INPUT"

EXEC_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$APP/Info.plist")
BIN="$APP/$EXEC_NAME"
[[ -f "$BIN" ]] || fail "$EXEC_NAME binary missing in $APP"

echo "==> auditing $(basename "$INPUT")"

file "$BIN" | grep -Eq "Mach-O 64-bit executable arm64" ||
    fail "$EXEC_NAME is not an arm64 device executable"

has_platform() {
    local path="$1" platform="$2"
    local out
    out=$(otool -l "$path" 2>/dev/null) || return 1
    grep -Eq "platform ${platform}([[:space:]]|$)" <<<"$out"
}

if ! has_platform "$BIN" 2; then
    fail "$EXEC_NAME binary is not device (platform 2)"
fi
if has_platform "$BIN" 7; then
    fail "$EXEC_NAME binary contains simulator objects"
fi

for ver in 18 19 31; do
    sym="_mkxp_get_script_binding_${ver}"
    nm "$BIN" 2>/dev/null | awk -v sym="$sym" '$3 == sym {found=1} END {exit !found}' ||
        fail "$EXEC_NAME binary missing ${sym}"
done

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Info.plist")

[[ "$BUNDLE_ID" == "app.xppocket.player" ]] ||
    fail "unexpected bundle id: $BUNDLE_ID (expected app.xppocket.player for release IPA)"

if [[ -n "$EXPECTED_VERSION" && "$VERSION" != "$EXPECTED_VERSION" ]]; then
    fail "Info.plist version $VERSION != expected $EXPECTED_VERSION"
fi

HEAD_COMMIT=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
EMBEDDED_COMMIT=$(grep -m1 -E '^commit: [0-9a-f]+$' < <(strings "$BIN") | awk '{print $2}')
[[ -n "$EMBEDDED_COMMIT" ]] || fail "embedded GitInfo commit not found in binary"
[[ "$EMBEDDED_COMMIT" == "$HEAD_COMMIT" ]] ||
    fail "embedded commit $EMBEDDED_COMMIT != HEAD $HEAD_COMMIT"

if grep -Eq ' \(dirty\)' < <(strings "$BIN"); then
    fail "binary embeds dirty GitInfo marker"
fi

SIZE=$(stat -f%z "$BIN")
[[ "$SIZE" -ge 25000000 ]] || fail "$EXEC_NAME binary suspiciously small (${SIZE} bytes)"

echo "OK: release artifact audit passed"
echo "    bundle: $BUNDLE_ID"
echo "    version: $VERSION ($BUILD)"
echo "    commit: $EMBEDDED_COMMIT"
echo "    binary: ${SIZE} bytes"
