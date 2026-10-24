#!/usr/bin/env bash
# Re-export FlatPark's patches from the fork into debian/patches/flatpark/.
#
#   packages/flatpak/sync-patches.sh [path-to-flatpak-fork]
#
# The fork (https://github.com/flatpark/flatpak) keeps one branch per Debian
# base version, flatpark/<upstream version>, holding FlatPark's commits on top
# of the upstream tag of the same name. The fork defaults to a checkout next to
# this repository (../flatpak).
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"

FORK="${1:-$ROOT/../flatpak}"
VERSION="$(upstream_version flatpak)"
BRANCH="flatpark/$VERSION"
PATCHES="$(pkg_dir flatpak)/debian/patches"

git -C "$FORK" rev-parse -q --verify "$BRANCH" >/dev/null || die "no branch $BRANCH in $FORK"
git -C "$FORK" rev-parse -q --verify "refs/tags/$VERSION" >/dev/null || die "no tag $VERSION in $FORK"

rm -rf "$PATCHES/flatpark"
mkdir -p "$PATCHES/flatpark"
git -C "$FORK" format-patch --quiet --no-numbered --zero-commit --no-signature \
    -o "$PATCHES/flatpark" "$VERSION..$BRANCH"

# Debian's own patches first, then ours in commit order.
{
    grep -v '^flatpark/' "$PATCHES/series" || true
    (cd "$PATCHES" && ls flatpark/*.patch)
} > "$PATCHES/series.new"
mv "$PATCHES/series.new" "$PATCHES/series"

log "exported $(ls "$PATCHES/flatpark" | wc -l) patches from $BRANCH ($(git -C "$FORK" rev-parse --short "$BRANCH"))"
