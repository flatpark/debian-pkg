#!/usr/bin/env bash
# Debian sid's flatpak source version (with Debian revision), as {"version": "..."}.
# This package rebases onto Debian's, not onto upstream releases.
set -euo pipefail
v="$(curl -fsS 'https://api.ftp-master.debian.org/madison?package=flatpak&s=sid&a=source&text=on' |
    awk -F'|' '{gsub(/ /, "", $2); print $2}' | sort -V | tail -n1)"
[ -n "$v" ] || { echo "no sid version found" >&2; exit 1; }
jq -n --arg v "$v" '{version: $v}'
