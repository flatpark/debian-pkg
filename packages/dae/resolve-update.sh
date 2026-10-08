#!/usr/bin/env bash
# Update resolver for dae (same contract as FlatPark's resolvers).
#
# Prints the current version + the Linux x86_64 release tarball as JSON:
#   { "version": "2.1.1", "releaseDate": "YYYY-MM-DD",
#     "sources": [ { "filename": "dae.tar.xz", "url": "..." } ] }
# Logs go to stderr. /releases/latest skips upstream's pre-releases.
set -euo pipefail

repo="daeuniverse/dae"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; exit 1; }; }
need curl; need jq

rel="$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
        "https://api.github.com/repos/$repo/releases/latest")"

version="$(jq -r '.tag_name | ltrimstr("v")' <<<"$rel")"
date="$(jq -r '.published_at' <<<"$rel" | cut -c1-10)"
# Every arch ships .deb/.rpm/.zip/.tar.xz plus .dgst files, and x86_64 also
# has _v2_sse and _v3_avx2 builds. Take the baseline x86_64 tarball exactly.
url="$(jq -r '.assets[] | select(.name == "dae-linux-x86_64.tar.xz") | .browser_download_url' \
        <<<"$rel" | head -n1)"

[ -n "$version" ] && [ -n "$url" ] || { echo "failed to resolve dae release" >&2; exit 1; }
echo "resolved dae $version ($date): $url" >&2

jq -n --arg v "$version" --arg d "$date" --arg u "$url" \
  '{version:$v, releaseDate:$d, sources:[{filename:"dae.tar.xz", url:$u}]}'
