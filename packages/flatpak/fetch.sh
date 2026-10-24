#!/usr/bin/env bash
# flatpak: the upstream release tarball (the same file Debian uses as its
# .orig.tar.xz), with Debian's packaging plus FlatPark's patches on top.
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"
VERSION="$1" WORK="$2"
TREE="$WORK/flatpak-$VERSION"

cd "$WORK"
fetch_pinned flatpak "flatpak_${VERSION}.orig.tar.xz"
rm -rf "$TREE"
mkdir "$TREE"
tar -xJf "flatpak_${VERSION}.orig.tar.xz" -C "$TREE" --strip-components=1 --no-same-owner
overlay_debian flatpak "$TREE"
