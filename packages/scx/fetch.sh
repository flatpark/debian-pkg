#!/usr/bin/env bash
# scx: sched_ext schedulers from the sched-ext/scx release tag.
set -euo pipefail
. "$(dirname "$0")/../../scripts/lib.sh"
VERSION="$1" WORK="$2"
"$ROOT/scripts/cargo/fetch-tag.sh" scx https://github.com/sched-ext/scx "$VERSION" "$WORK"

# Install manifest: every scheduler that exists in this release, so new or
# removed schedulers need no packaging edit.
TREE="$WORK/scx-$VERSION"
{
    echo 'services/scx etc/default/'
    ls -d "$TREE"/scheds/rust/scx_* | sed 's|.*/\(scx_.*\)$|target/release/\1 usr/sbin/|'
} > "$TREE/debian/install"
