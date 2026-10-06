#!/usr/bin/env bash
# Gather the apt index inputs from GitHub Releases.
#
#   scripts/collect-index.sh <out-dir>
#
# Every release <source>_<version> carries its .debs plus <tag>.packages (the
# index stanzas build-in-container.sh wrote). For each source this keeps the
# newest KEEP versions (default 2: current + one to roll back to with
# `apt install pkg=<version>`) and downloads only their small .packages files:
#   <out>/stanzas/<tag>.packages
# The newest flatpark-archive-keyring .deb is also fetched to
# <out>/flatpark-archive-keyring.deb, the bootstrap download.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

OUT="${1:?usage: $0 <out-dir>}"
KEEP="${KEEP:-2}"
REPO="${GITHUB_REPOSITORY:-flatpark/debian-pkg}"
mkdir -p "$OUT/stanzas"

# "<source> <version> <tag>", newest first within each source.
list="$(gh release list -R "$REPO" -L 1000 --exclude-drafts --exclude-pre-releases \
            --json tagName -q '.[].tagName' |
        while read -r tag; do
            case "$tag" in *_*) ;; *) continue ;; esac   # not a package release
            read -r src ver < <(parse_tag "$tag")
            printf '%s %s %s\n' "$src" "$ver" "$tag"
        done)"
[ -n "$list" ] || die "no package releases found in $REPO"

for src in $(cut -d' ' -f1 <<<"$list" | sort -u); do
    # Debian version order, not sort -V: "~" sorts before everything.
    tags="$(awk -v s="$src" '$1 == s {print $2, $3}' <<<"$list" |
            while read -r v t; do
                printf '%s %s\n' "$v" "$t"
            done | {
                mapfile -t rows
                for ((i = 1; i < ${#rows[@]}; i++)); do
                    for ((j = i; j > 0; j--)); do
                        dpkg --compare-versions "${rows[j]%% *}" gt "${rows[j-1]%% *}" || break
                        tmp="${rows[j]}"; rows[j]="${rows[j-1]}"; rows[j-1]="$tmp"
                    done
                done
                printf '%s\n' "${rows[@]}"
            } | head -n "$KEEP" | cut -d' ' -f2)"
    for tag in $tags; do
        log "$tag"
        gh release download "$tag" -R "$REPO" -p "$tag.packages" -D "$OUT/stanzas" --clobber
    done
    if [ "$src" = flatpark-archive-keyring ]; then
        newest="$(head -n1 <<<"$tags")"
        gh release download "$newest" -R "$REPO" -p '*.deb' -O "$OUT/flatpark-archive-keyring.deb" --clobber
    fi
done
