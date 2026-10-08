#!/usr/bin/env bash
# dae: the official x86_64 release tarball, repackaged unmodified.
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"
VERSION="$1" WORK="$2"
TREE="$WORK/dae-$VERSION"

cd "$WORK"
fetch_pinned dae "dae_${VERSION}.orig.tar.xz"
rm -rf "$TREE"
mkdir "$TREE"
# Upstream lays the tarball out as the install root (./usr, ./etc).
tar -xJf "dae_${VERSION}.orig.tar.xz" -C "$TREE" --no-same-owner
overlay_debian dae "$TREE"
