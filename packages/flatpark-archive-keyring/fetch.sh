#!/usr/bin/env bash
# Native package: the tree is this directory itself (public key + source).
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"
VERSION="$1" WORK="$2"
PKG="$(pkg_dir flatpark-archive-keyring)"
TREE="$WORK/flatpark-archive-keyring-$VERSION"
[ -s "$PKG/flatpark-archive-keyring.asc" ] || die "no public key yet: run scripts/gen-signing-key.sh"
rm -rf "$TREE"; mkdir -p "$TREE"
cp "$PKG/flatpark-archive-keyring.asc" "$PKG/flatpark.sources" "$TREE/"
overlay_debian flatpark-archive-keyring "$TREE"
