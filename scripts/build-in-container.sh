#!/usr/bin/env bash
# Build one package inside a throwaway debian:sid container. Run by build.sh
# (locally) and by the build workflow; not meant to be run on a host.
#
#   scripts/build-in-container.sh <source> <out-dir>
#
# 1. install the package's Build-Depends (read from packages/<src>/debian)
# 2. packages/<src>/fetch.sh <upstream-version> <work-dir> must leave a source
#    tree at <work-dir>/<src>-<upstream-version>/ with debian/ in place
#    (helpers: overlay_debian below)
# 3. dpkg-buildpackage -b, then install the result into the same container,
#    which proves its Depends resolve against sid, and run the package's
#    optional smoke.sh
# 4. copy the .debs to <out-dir> under release-safe names, plus
#    <tag>.packages: their apt index stanzas with Filename: pool/<tag>/<deb>,
#    which publish.sh stitches into the repository index
set -euo pipefail
. "$(dirname "$0")/lib.sh"

SRC="${1:?usage: $0 <source> <out-dir>}"
OUT="${2:?usage: $0 <source> <out-dir>}"
PKG="$(pkg_dir "$SRC")"
VERSION="$(upstream_version "$SRC")"
TAG="$(release_tag "$SRC")"
WORK=/build
export DEBIAN_FRONTEND=noninteractive

log "$SRC $(deb_version "$SRC") (tag $TAG)"

apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    build-essential devscripts equivs fakeroot apt-utils \
    ca-certificates curl git jq python3 xz-utils >/dev/null
# Build-Depends straight from the packaging directory; fetch.sh may need some
# of them too (cargo vendor, for one).
mk-build-deps --install --remove \
    --tool 'apt-get -y -qq --no-install-recommends' "$PKG/debian/control" >/dev/null

mkdir -p "$WORK"
"$PKG/fetch.sh" "$VERSION" "$WORK"
TREE="$WORK/$SRC-$VERSION"
[ -f "$TREE/debian/changelog" ] || die "fetch.sh left no tree at $TREE"

(cd "$TREE" && dpkg-buildpackage -b -us -uc)

shopt -s nullglob
debs=("$WORK"/*.deb)
[ ${#debs[@]} -gt 0 ] || die "no .deb produced"

log "install test"
# A dependency on another package of this repository (scx-loader -> scx)
# cannot come from sid, and that package may not be published yet. Stand in
# for it with an equivs stub at its current changelog version; every other
# dependency must still resolve against sid.
own="$(for d in "${debs[@]}"; do dpkg-deb -f "$d" Package; done)"
deps="$(for d in "${debs[@]}"; do dpkg-deb -f "$d" Depends; done |
        tr ',|' '\n\n' | sed 's/(.*//; s/[[:space:]]//g' | sort -u)"
for ctl in "$ROOT"/packages/*/debian/control; do
    sib_src="$(basename "$(dirname "$(dirname "$ctl")")")"
    sib_ver="$(deb_version "$sib_src")"
    for sib in $(sed -n 's/^Package: *//p' "$ctl"); do
        grep -qx "$sib" <<<"$deps" || continue
        grep -qx "$sib" <<<"$own" && continue
        log "stub for sibling package $sib $sib_ver"
        (cd "$WORK" &&
            printf 'Package: %s\nVersion: %s\nArchitecture: all\nDescription: install-test stub\n' \
                "$sib" "$sib_ver" > "stub-$sib" &&
            equivs-build "stub-$sib" >/dev/null)
        apt-get install -y -qq "$WORK/${sib}_${sib_ver}_all.deb" >/dev/null
        rm -f "$WORK/${sib}_${sib_ver}_all.deb" "$WORK/stub-$sib"
    done
done
apt-get install -y -qq "${debs[@]}" >/dev/null
if [ -x "$PKG/smoke.sh" ]; then
    log "smoke test"
    "$PKG/smoke.sh"
fi

mkdir -p "$OUT" "$WORK/index/pool/$TAG"
for deb in "${debs[@]}"; do
    name="$(safe_name "${deb##*/}")"
    cp "$deb" "$OUT/$name"
    cp "$deb" "$WORK/index/pool/$TAG/$name"
done
(cd "$WORK/index" && apt-ftparchive packages pool) > "$OUT/$TAG.packages"

log "artifacts:"
ls -l "$OUT" >&2
