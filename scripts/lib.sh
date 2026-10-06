# Shared helpers, sourced by the scripts in this directory and by each
# package's fetch.sh / resolve-update.sh.
#
# A package is a directory packages/<source>/ holding:
#   debian/             the Debian packaging; debian/changelog is the single
#                       source of truth for the version being built
#   fetch.sh            turns that version into a ready-to-build tree
#                       (see scripts/build-in-container.sh for the contract)
#   resolve-update.sh   optional; prints the newest upstream release as JSON
#   meta.json           optional; upstream pin + update policy
#
# Every built version becomes one GitHub Release tagged <source>_<version>.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { printf '>> %s\n' "$*" >&2; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

pkg_dir() {  # pkg_dir <source>
    local d="$ROOT/packages/$1"
    [ -f "$d/debian/changelog" ] || die "unknown package: $1"
    printf '%s\n' "$d"
}

all_sources() {
    local d
    for d in "$ROOT"/packages/*/debian/changelog; do
        d="${d%/debian/changelog}"
        printf '%s\n' "${d##*/}"
    done
}

# Full Debian version from the top changelog entry (e.g. 0.21.0-1).
deb_version() {  # deb_version <source>
    sed -n '1s/^[^ ]* (\([^)]*\)).*/\1/p' "$(pkg_dir "$1")/debian/changelog"
}

# Upstream part: strip the Debian revision.
upstream_version() {  # upstream_version <source>
    local v; v="$(deb_version "$1")"
    printf '%s\n' "${v%-*}"
}

# Git tags cannot contain "~" or ":". Debian versions never contain "_", and
# neither do source names, so "_" is a safe, reversible substitute for "~".
# Epochs are not supported: nothing here needs one.
release_tag() {  # release_tag <source> [version]
    local v="${2:-$(deb_version "$1")}"
    case "$v" in *:*) die "$1: epochs are not supported ($v)" ;; esac
    printf '%s_%s\n' "$1" "${v//\~/_}"
}

# Inverse of release_tag: prints "<source> <version>".
parse_tag() {  # parse_tag <tag>
    local src="${1%%_*}" v="${1#*_}"
    printf '%s %s\n' "$src" "${v//_/\~}"
}

# Release asset names: GitHub rewrites unusual characters, so make the .deb
# file names boring before upload and index them under the same name.
safe_name() {  # safe_name <file name>
    printf '%s\n' "$1" | sed 's/[^A-Za-z0-9._-]/_/g'
}

maintainer() {  # maintainer <source>
    sed -n 's/^Maintainer: *//p' "$(pkg_dir "$1")/debian/control" | head -n1
}

# Copy packages/<src>/debian into a fetched source tree.
overlay_debian() {  # overlay_debian <source> <tree>
    rm -rf "$2/debian"
    cp -r "$(pkg_dir "$1")/debian" "$2/debian"
}

# Download the upstream artifact pinned in meta.json (.source.url/.sha256) and
# verify it. Refuses a pin whose URL does not mention the changelog version,
# so a changelog bump without a matching re-pin fails loudly.
fetch_pinned() {  # fetch_pinned <source> <dest-file>
    local meta url sum ver
    meta="$(pkg_dir "$1")/meta.json"
    url="$(jq -er '.source.url' "$meta")" || die "$1: no .source.url in meta.json"
    sum="$(jq -er '.source.sha256' "$meta")" || die "$1: no .source.sha256 in meta.json"
    ver="$(upstream_version "$1")"
    case "$url" in *"$ver"*) ;; *) die "$1: pinned URL does not match version $ver: $url" ;; esac
    log "download $url"
    curl -fsSL --retry 3 -o "$2" "$url"
    echo "$sum  $2" | sha256sum -c --quiet - || die "$1: sha256 mismatch for $url"
}
