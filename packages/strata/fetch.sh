#!/usr/bin/env bash
# strata: the official x86_64 release tarball, repackaged unmodified.
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"
VERSION="$1" WORK="$2"
TREE="$WORK/strata-$VERSION"

cd "$WORK"
fetch_pinned strata "strata_${VERSION}.orig.tar.gz"
rm -rf "$TREE"
mkdir "$TREE"
tar -xzf "strata_${VERSION}.orig.tar.gz" -C "$TREE" --strip-components=1 --no-same-owner
overlay_debian strata "$TREE"
