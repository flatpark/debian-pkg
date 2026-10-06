#!/usr/bin/env bash
# Assemble the signed apt index for https://apt.flatpark.org.
#
#   GPG_KEY_ID=<master fingerprint> scripts/build-apt-repo.sh <collected-dir> <out-dir>
#
# <collected-dir> is what collect-index.sh produced. Only metadata is built
# here; the .debs stay in GitHub Releases and the Worker redirects
# pool/<tag>/<file> to them (worker/src/index.js). Every .deb's size and
# hashes are in the signed index, so apt verifies whatever the redirect serves.
#
# Output (uploaded to R2 by publish.yml):
#   dists/sid/{InRelease,Release,Release.gpg}
#   dists/sid/main/binary-amd64/Packages{,.gz,.xz}
#   dists/sid/main/binary-amd64/by-hash/SHA256/<sum>   (Acquire-By-Hash)
#   flatpark-archive-keyring.{gpg,asc}, flatpark.sources, index.html
#   flatpark-archive-keyring.deb   (when collected)
#
# GPG_KEY_ID is the certify-only master; gpg signs with its signing subkey,
# which is the only secret CI holds.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

IN="$(cd "${1:?usage: $0 <collected-dir> <out-dir>}" && pwd)"
OUT="${2:?usage: $0 <collected-dir> <out-dir>}"
: "${GPG_KEY_ID:?set GPG_KEY_ID to the master fingerprint of the signing key}"

DOMAIN=apt.flatpark.org
SUITE=sid COMP=main ARCH=amd64
KEYRING=flatpark-archive-keyring

shopt -s nullglob
stanzas=("$IN"/stanzas/*.packages)
[ ${#stanzas[@]} -gt 0 ] || die "no stanzas in $IN/stanzas"

rm -rf "$OUT"
bin="dists/$SUITE/$COMP/binary-$ARCH"
mkdir -p "$OUT/$bin/by-hash/SHA256"
cd "$OUT"

# Each stanza already ends with a blank line.
cat "${stanzas[@]}" > "$bin/Packages"
gzip -9nk "$bin/Packages"
xz -9k "$bin/Packages"
for f in "$bin"/Packages "$bin"/Packages.gz "$bin"/Packages.xz; do
    cp "$f" "$bin/by-hash/SHA256/$(sha256sum "$f" | cut -d' ' -f1)"
done

apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=FlatPark \
    -o APT::FTPArchive::Release::Label=FlatPark \
    -o APT::FTPArchive::Release::Suite=unstable \
    -o APT::FTPArchive::Release::Codename="$SUITE" \
    -o APT::FTPArchive::Release::Architectures="$ARCH" \
    -o APT::FTPArchive::Release::Components="$COMP" \
    -o APT::FTPArchive::Release::Acquire-By-Hash=yes \
    -o APT::FTPArchive::Release::Description="FlatPark native packages for Debian sid (not sandboxed)" \
    release "dists/$SUITE" > "dists/$SUITE/Release.tmp"
mv "dists/$SUITE/Release.tmp" "dists/$SUITE/Release"

gpg --batch --yes --local-user "$GPG_KEY_ID" --digest-algo SHA512 \
    --clearsign -o "dists/$SUITE/InRelease" "dists/$SUITE/Release"
gpg --batch --yes --local-user "$GPG_KEY_ID" --digest-algo SHA512 \
    --armor --detach-sign -o "dists/$SUITE/Release.gpg" "dists/$SUITE/Release"

gpg --batch --export "$GPG_KEY_ID" > "$KEYRING.gpg"
gpg --batch --armor --export "$GPG_KEY_ID" > "$KEYRING.asc"
if [ -f "$IN/$KEYRING.deb" ]; then cp "$IN/$KEYRING.deb" "$KEYRING.deb"; fi

cat > flatpark.sources <<EOF
Types: deb
URIs: https://$DOMAIN
Suites: $SUITE
Components: $COMP
Architectures: $ARCH
Signed-By: /usr/share/keyrings/$KEYRING.gpg
EOF

packages="$(awk -F': ' '/^Package:/{p=$2} /^Version:/{print p, $2}' "$bin/Packages" | sort -V)"
cat > index.html <<EOF
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$DOMAIN</title>
<style>body{font:15px/1.5 system-ui,sans-serif;max-width:46rem;margin:2rem auto;padding:0 1rem}pre{background:#8881;padding:.8rem;overflow-x:auto}</style>
<h1>$DOMAIN</h1>
<p>FlatPark's apt repository for Debian sid (amd64): native packages, installed
on the host and <strong>not sandboxed</strong>. Packaging:
<a href="https://github.com/flatpark/debian-pkg">flatpark/debian-pkg</a>.</p>
<pre>curl -fsSLO https://$DOMAIN/$KEYRING.deb
sudo apt install ./$KEYRING.deb
sudo apt update</pre>
<h2>Packages</h2>
<pre>$packages</pre>
EOF

log "repo ready in $OUT"
find . -type f | sort >&2
