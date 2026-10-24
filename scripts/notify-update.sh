#!/usr/bin/env bash
# Report, without changing anything, whether a package with "update": "issue"
# has fallen behind its resolver.
#
#   scripts/notify-update.sh <source>
#
# Such a package carries local changes on top of a base version, marked by a
# "+<suffix>" on its changelog version (1.18.4-1+flatpark1 is based on
# 1.18.4-1). The resolver prints {"version": ...} in the same form as that
# base, and a newer one is printed here. Prints nothing when current.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

SRC="${1:?usage: $0 <source>}"
PKG="$(pkg_dir "$SRC")"
[ -x "$PKG/resolve-update.sh" ] || die "$SRC: no resolver"

new="$(cd "$PKG" && ./resolve-update.sh | jq -er '.version')" || die "$SRC: resolver printed no version"
base="$(deb_version "$SRC")"
base="${base%%+*}"

if dpkg --compare-versions "$new" gt "$base"; then
    log "$SRC: $base -> $new"
    printf '%s\n' "$new"
else
    log "$SRC: up to date ($base, resolver $new)"
fi
