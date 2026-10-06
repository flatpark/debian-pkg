#!/usr/bin/env bash
# Bump one package to its newest upstream release.
#
#   scripts/check-update.sh <source>
#
# Runs packages/<src>/resolve-update.sh, which prints FlatPark's resolver JSON:
#   { "version": "1.2.3", "sources": [ { "url": "https://..." } ] }
# ("sources" only for packages that repack a pinned artifact). When the version
# is newer than debian/changelog, re-pins meta.json (.source url + sha256),
# prepends a "-1" changelog entry and prints the new upstream version. Prints
# nothing when the package is current. Never commits.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

SRC="${1:?usage: $0 <source>}"
PKG="$(pkg_dir "$SRC")"
[ -x "$PKG/resolve-update.sh" ] || { log "$SRC: no resolver"; exit 0; }

json="$(cd "$PKG" && ./resolve-update.sh)"
new="$(jq -er '.version' <<<"$json")" || die "$SRC: resolver printed no version"
# Upstream pre-release markers (1.0-rc1) must sort before the release: "~".
new="${new//-/\~}"
cur="$(upstream_version "$SRC")"

if ! dpkg --compare-versions "$new" gt "$cur"; then
    log "$SRC: up to date ($cur, upstream $new)"
    exit 0
fi
log "$SRC: $cur -> $new"

url="$(jq -r '.sources[0].url // empty' <<<"$json")"
if [ -n "$url" ]; then
    [ "$(jq '.sources | length' <<<"$json")" = 1 ] || die "$SRC: only one pinned source is supported"
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
    curl -fsSL --retry 3 -o "$tmp" "$url"
    sum="$(sha256sum "$tmp" | cut -d' ' -f1)"
    meta="$PKG/meta.json"
    [ -f "$meta" ] || echo '{}' > "$meta"
    jq --arg u "$url" --arg s "$sum" '.source = {url: $u, sha256: $s}' "$meta" > "$meta.new"
    mv "$meta.new" "$meta"
fi

cl="$PKG/debian/changelog"
{
    printf '%s (%s-1) unstable; urgency=medium\n\n' "$SRC" "$new"
    printf '  * New upstream release %s.\n\n' "$new"
    printf ' -- %s  %s\n\n' "$(maintainer "$SRC")" "$(date -R)"
    cat "$cl"
} > "$cl.new"
mv "$cl.new" "$cl"

printf '%s\n' "$new"
