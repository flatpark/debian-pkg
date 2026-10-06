#!/usr/bin/env bash
# Shared fetch for the Rust packages built from an upstream git tag:
# clone v<version>, vendor every crate for an offline build, pack the orig
# tarball, overlay debian/ and refresh the vendored-crates copyright block.
#
#   scripts/cargo/fetch-tag.sh <source> <git-url> <version> <work-dir>
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

SRC="$1" URL="$2" VERSION="$3" WORK="$4"
TREE="$SRC-$VERSION"
HERE="$(cd "$(dirname "$0")" && pwd)"

cd "$WORK"
rm -rf "$TREE" "${SRC}_${VERSION}.orig.tar.gz"
log "clone $URL v$VERSION"
git clone -q --depth 1 --branch "v$VERSION" "$URL" "$TREE"
rm -rf "$TREE/.git"

overlay_debian "$SRC" "$TREE"
# The build re-runs the checksum sanitizer from debian/; both helpers live
# once in scripts/cargo/.
cp "$HERE/sanitize-vendor-checksums.py" "$HERE/update-vendor-copyright" "$TREE/debian/"

(
    cd "$TREE"
    # `cargo vendor` prints the source-replacement config; append it to
    # upstream's own .cargo/config.toml so their aliases survive.
    mkdir -p .cargo
    cargo vendor -q >> .cargo/config.toml
    python3 debian/sanitize-vendor-checksums.py --copyright debian/copyright
    python3 debian/update-vendor-copyright --source-root .
)

tar --create --gzip --owner=0 --group=0 --numeric-owner \
    --exclude="$TREE/debian" -f "${SRC}_${VERSION}.orig.tar.gz" "$TREE"
