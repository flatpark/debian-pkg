#!/usr/bin/env bash
# Print a JSON array of package sources for a workflow matrix.
#
#   scripts/select-sources.sh changed <base-sha> <head-sha>
#       packages touched between the two commits; every package when the
#       shared build scripts changed
#   scripts/select-sources.sh unreleased
#       packages whose changelog version has no GitHub Release yet, except
#       those with "publish": false in meta.json
#   scripts/select-sources.sh updatable
#       packages with a resolve-update.sh that update by PR (the default)
#   scripts/select-sources.sh notify
#       packages with a resolve-update.sh and "update": "issue" in meta.json
set -euo pipefail
. "$(dirname "$0")/lib.sh"

case "${1:-}" in
changed)
    files="$(git -C "$ROOT" diff --name-only "$2" "$3")"
    if grep -qE '^(build\.sh|scripts/)' <<<"$files"; then
        all_sources
    else
        sed -n 's|^packages/\([^/]*\)/.*|\1|p' <<<"$files" | sort -u |
            while read -r s; do [ -f "$ROOT/packages/$s/debian/changelog" ] && echo "$s"; done
    fi
    ;;
unreleased)
    REPO="${GITHUB_REPOSITORY:-flatpark/debian-pkg}"
    for s in $(all_sources); do
        if [ "$(meta_get "$s" '.publish')" = false ]; then continue; fi
        gh release view "$(release_tag "$s")" -R "$REPO" >/dev/null 2>&1 || echo "$s"
    done
    ;;
updatable|notify)
    for s in $(all_sources); do
        [ -x "$ROOT/packages/$s/resolve-update.sh" ] || continue
        mode="$(meta_get "$s" '.update')"
        if [ "$1" = notify ]; then want=issue; else want=pr; fi
        if [ "$mode" = issue ]; then have=issue; else have=pr; fi
        if [ "$have" = "$want" ]; then echo "$s"; fi
    done
    ;;
*) die "usage: $0 changed <base> <head> | unreleased | updatable | notify" ;;
esac | jq -Rnc '[inputs | select(length > 0)]'
