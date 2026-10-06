#!/usr/bin/env bash
# The installed keyring must hold the key and apt must parse the source.
set -euo pipefail
gpg --show-keys /usr/share/keyrings/flatpark-archive-keyring.gpg
apt-get indextargets >/dev/null
