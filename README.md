# FlatPark debian-pkg

Debian packages picked by [FlatPark](https://flatpark.org), published as the
apt repository **https://apt.flatpark.org**.

Unlike FlatPark's Flatpaks, these are **native packages**: they install on
the host and are **not sandboxed**. There is no upstream-approval process;
the selection is simply software worth having on a Debian sid desktop.

**Supported platform: Debian sid (unstable), amd64.** Packages are built
against current sid and are not expected to work on stable.

## Install

```sh
curl -fsSLO https://apt.flatpark.org/flatpark-archive-keyring.deb
sudo apt install ./flatpark-archive-keyring.deb
sudo apt update
```

The keyring package installs the signing key and the apt source, and keeps
both current through later upgrades.

## Packages

| Package | What | Built from |
| --- | --- | --- |
| [dae](packages/dae/) | dae, eBPF transparent proxy + `dae.service` | upstream release binary, repackaged |
| [scx](packages/scx/) | sched_ext CPU schedulers + `scx.service` | source (release tag) |
| [scx-loader](packages/scx-loader/) | `scx_loader` daemon, `scxctl`, `scxtui` | source (release tag) |
| [strata](packages/strata/) | Strata, keyboard-first GTK 4 file manager | upstream release binary, repackaged |
| [flatpark-archive-keyring](packages/flatpark-archive-keyring/) | the repository's key and apt source | this repo |

Each package directory has its own README with usage and packaging notes.

## How it works

```
packages/<source>/
  debian/             standard Debian packaging; debian/changelog is the
                      single source of truth for the version
  fetch.sh            version -> ready-to-build source tree
  resolve-update.sh   newest upstream release (FlatPark's resolver JSON)
  meta.json           upstream pin (url + sha256) and "automerge" policy
  smoke.sh            optional post-install check
  README.md
```

- **Build.** `./build.sh <source>` runs everything in a throwaway
  `debian:sid` container (podman or docker): install Build-Depends, `fetch.sh`,
  `dpkg-buildpackage -b`, install the result (proves `Depends` resolve on
  sid), run `smoke.sh`. Source builds and binary repacks take the same path.
- **Release.** On every push to `main`, each package whose changelog version
  has no GitHub Release yet is built and released as `<source>_<version>`,
  carrying its `.deb`s and a `<tag>.packages` index stanza. Releases are never
  overwritten. To rebuild an unchanged package (a sid library transition, for
  example), add a changelog entry with the next Debian revision.
- **Publish.** `publish.yml` stitches the stanzas of the newest two versions
  of each package into a signed index (`Acquire-By-Hash`) and uploads only that
  metadata to R2. The Cloudflare Worker in `worker/` serves it at
  apt.flatpark.org and redirects `pool/<tag>/<file>.deb` to the GitHub Release
  asset. apt verifies every `.deb` against the signed hashes, so the redirect
  costs no trust, and package bytes never touch R2.
- **Updates.** `update-check.yml` runs each resolver daily. A newer upstream
  version gets a changelog entry and a re-pin, is built and tested, and lands
  as a PR from `auto/update-<source>`. Packages with `"automerge": true` are
  merged and released right away; the rest wait for review.
- **CI.** Pull requests build every package they touch (all packages when
  `build.sh` or `scripts/` change).

## Adding a package

1. Create `packages/<source>/` with `debian/`, `fetch.sh` and a README.
   - Repacking an upstream binary: copy `packages/strata/`, pin the artifact
     in `meta.json`, use `fetch_pinned`.
   - Building a Rust project from a tag: copy `packages/scx-loader/`, which
     uses `scripts/cargo/fetch-tag.sh`.
2. Add `resolve-update.sh` so the update check tracks it, and `smoke.sh` if a
   quick check fits.
3. `./build.sh <source>` locally, open a PR, merge. The release follows.

## Maintaining the repository

One-time setup, already done for the live repository:

1. **Signing key.** `scripts/gen-signing-key.sh <backup-file>` creates a
   certify-only master and a signing subkey, stores the subkey as the
   `APT_SIGNING_SUBKEY` secret and the master fingerprint as the
   `APT_SIGNING_FPR` variable, and writes the public key into the keyring
   package. Keep the master backup offline.
2. **R2.** Bucket `flatpark-apt`; secrets `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`,
   `R2_SECRET_ACCESS_KEY` (object read/write on that bucket).
3. **Worker.** Secrets `CLOUDFLARE_API_TOKEN` (Workers edit, R2 read, zone
   flatpark.org routes) and `CLOUDFLARE_ACCOUNT_ID`; `deploy-worker.yml`
   deploys `worker/` and binds `apt.flatpark.org` as a custom domain.

## History

This repository began as `jing2uo/scx-scheds-debian-sid`, which published scx
at `apt.guojing.io`. It moved to the FlatPark organization in October 2026
and became a general package repository. Users of the old source should
install `flatpark-archive-keyring` and remove
`/etc/apt/sources.list.d/guojing.sources`.
