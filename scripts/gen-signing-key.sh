#!/usr/bin/env bash
# One-time: create the apt.flatpark.org archive key.
#
#   scripts/gen-signing-key.sh <backup-file>
#
# Same structure as FlatPark's Flatpak repository key:
#   master  = certify-only, the root of trust. Exported once to <backup-file>;
#             keep that offline (encrypted) and never give it to CI.
#   subkey  = sign-only, the key that signs InRelease. Its secret becomes the
#             APT_SIGNING_SUBKEY repository secret.
# Writes the public key to packages/flatpark-archive-keyring/, so the keyring
# package ships it, and prints the master fingerprint for the APT_SIGNING_FPR
# repository variable. Rotating the subkey later: import the backup, add a
# new sign subkey, re-run the export steps below, bump the keyring package.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
BACKUP="${1:?usage: $0 <backup-file>}"
[ ! -e "$BACKUP" ] || die "$BACKUP already exists"
REPO="${REPO:-flatpark/debian-pkg}"
UID_="FlatPark APT Archive <sign@flatpark.org>"

GNUPGHOME="$(mktemp -d)"; export GNUPGHOME
trap 'rm -rf "$GNUPGHOME"' EXIT

gpg --batch --passphrase '' --quick-generate-key "$UID_" ed25519 cert never
fpr="$(gpg --list-keys --with-colons | awk -F: '/^fpr:/{print $10; exit}')"
gpg --batch --passphrase '' --quick-add-key "$fpr" ed25519 sign never

(umask 077; gpg --armor --export-secret-keys "$fpr" > "$BACKUP")
gpg --armor --export "$fpr" > "$ROOT/packages/flatpark-archive-keyring/flatpark-archive-keyring.asc"
gpg --armor --export-secret-subkeys "$fpr" | gh secret set APT_SIGNING_SUBKEY -R "$REPO"
gh variable set APT_SIGNING_FPR -R "$REPO" --body "$fpr"

log "master fingerprint: $fpr"
log "offline backup:     $BACKUP   (move it somewhere safe, then delete this copy)"
log "public key written: packages/flatpark-archive-keyring/flatpark-archive-keyring.asc (commit it)"
