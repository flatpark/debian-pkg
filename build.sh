#!/usr/bin/env bash
# Build packages locally in a debian:sid container (podman or docker); nothing
# is installed on the host. Artifacts land in out/<source>/.
#
#   ./build.sh strata
#   ./build.sh scx scx-loader
#   ./build.sh            # every package
#
# DEB_BUILD_OPTIONS defaults to "nocheck noautodbgsym parallel=<nproc>".
set -euo pipefail
. "$(dirname "$0")/scripts/lib.sh"

if command -v podman >/dev/null 2>&1; then RUNNER=podman
elif command -v docker >/dev/null 2>&1; then RUNNER=docker
else die "podman or docker is required"; fi

[ $# -gt 0 ] || set -- $(all_sources)

for src in "$@"; do
    pkg_dir "$src" >/dev/null
    rm -rf "$ROOT/out/$src"
    mkdir -p "$ROOT/out/$src"
    "$RUNNER" run --rm \
        -e DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:-nocheck noautodbgsym parallel=$(nproc)}" \
        -v "$ROOT:/src:ro" \
        -v "$ROOT/out/$src:/out" \
        docker.io/library/debian:sid \
        /src/scripts/build-in-container.sh "$src" /out
done
