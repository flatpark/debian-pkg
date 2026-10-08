#!/usr/bin/env bash
# The shipped example config passes dae's own offline check (alias and
# geosite/geoip resolution against /usr/share/dae; no BPF, no network), and
# keeps the 0640 mode dae insists on.
set -euo pipefail
dae --version
[ "$(stat -c %a /etc/dae/example.dae)" = 640 ]
dae validate -c /etc/dae/example.dae
