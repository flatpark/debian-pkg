#!/usr/bin/env bash
# Print a JSON array of package sources for a workflow matrix.
#
#   scripts/select-sources.sh changed <base-sha> <head-sha>
#       packages touched between the two commits; every package when the
#       shared build scripts changed
#   scripts/select-sources.sh unreleased
#       packages whose changelog version has no GitHub Release yet
#   scripts/select-sources.sh updatable
#       packages with a resolve-update.sh
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
        gh release view "$(release_tag "$s")" -R "$REPO" >/dev/null 2>&1 || echo "$s"
    done
    ;;
updatable)
    for s in $(all_sources); do [ -x "$ROOT/packages/$s/resolve-update.sh" ] && echo "$s"; done
    ;;
*) die "usage: $0 changed <base> <head> | unreleased | updatable" ;;
esac | jq -Rnc '[inputs | select(length > 0)]'
