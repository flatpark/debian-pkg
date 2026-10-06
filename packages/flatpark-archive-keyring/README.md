# flatpark-archive-keyring

The OpenPGP key that signs https://apt.flatpark.org
(`/usr/share/keyrings/flatpark-archive-keyring.gpg`) and the deb822 source
that points apt at it (`/etc/apt/sources.list.d/flatpark.sources`).

It is the bootstrap download: installing it is all the setup the repository
needs (see the [root README](../../README.md#install)).

## The key

- A certify-only ed25519 master, kept offline, plus an ed25519 signing subkey.
  CI holds only the subkey (secret `APT_SIGNING_SUBKEY`).
- Created once with `scripts/gen-signing-key.sh`, which writes the public key
  to `flatpark-archive-keyring.asc` here.

To rotate the signing subkey: import the offline master, add a new sign
subkey (and expire the old one), export the public key over
`flatpark-archive-keyring.asc`, export the new secret subkey to
`APT_SIGNING_SUBKEY`, and add a changelog entry (version = date). Users get
the new key through `apt upgrade` before the old subkey stops being used.
