#!/usr/bin/env bash
# scx-loader: scx_loader daemon + scxctl + scxtui from sched-ext/scx-loader.
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"
VERSION="$1" WORK="$2"
"$ROOT/scripts/cargo/fetch-tag.sh" scx-loader https://github.com/sched-ext/scx-loader "$VERSION" "$WORK"

# Vendor-default config, staged under the name the loader looks up
# ($VENDORDIR/scx_loader/config.toml).
TREE="$WORK/scx-loader-$VERSION"
mkdir -p "$TREE/vendor-default"
cp "$TREE/configs/scx_loader.toml" "$TREE/vendor-default/config.toml"
