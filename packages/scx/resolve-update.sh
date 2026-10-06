#!/usr/bin/env bash
# Newest stable release tag of sched-ext/scx, as {"version": "..."}.
set -euo pipefail
v="$(git ls-remote --tags --refs https://github.com/sched-ext/scx 'refs/tags/v*' \
    | grep -Ev -- '-(rc|alpha|beta)' | sed 's|.*/v||' | sort -V | tail -n1)"
[ -n "$v" ] || { echo "no release tag found" >&2; exit 1; }
jq -n --arg v "$v" '{version: $v}'
