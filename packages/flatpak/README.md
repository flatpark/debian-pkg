# flatpak

Debian sid's `flatpak` with FlatPark's patches on top: a drop-in replacement for
`flatpak`, `libflatpak0` and the rest of the source package, so GNOME Software
and Discover pick up the changes too.

| Change | Effect |
| --- | --- |
| Parallel extra-data downloads | A transaction downloads every app's extra-data up front, 4 at a time, while installs still run one by one. Tune with `flatpak config --set extra-data-parallel N` or `FLATPAK_EXTRA_DATA_PARALLEL=N`; `1` restores upstream behaviour. |
| Drop cached extra-data after deploy | Upstream keeps each proprietary app's original download inside the repository (`xa.extra-data` in the commit's detached metadata) even though a reinstall downloads it again. It is now removed once the app is deployed; the commit's signature is kept. `flatpak config --set keep-extra-data true` keeps it. |
| `flatpak clean` | Removes the cache above from existing installations (`--dry-run` to preview, `--system` as root). |

The only thing the dropped cache was good for is redeploying the same commit
without pulling (`--no-pull`); that now fails with "Extra data missing in
detached metadata", and a normal reinstall fixes it.

## Installing a local build

The build produces Debian's usual split: `flatpak` (the CLI, system helper and
portal), `libflatpak0` (for GNOME Software / Discover), and the development
packages `libflatpak-dev`, `gir1.2-flatpak-1.0`, `libflatpak-doc`. On a desktop
install only what is already there, normally just the CLI:

```sh
sudo apt install ./out/flatpak/flatpak_*.deb
```

Never `dpkg -i out/flatpak/*.deb`: dpkg does not resolve dependencies, so the
development packages are left unconfigured and apt refuses to work until they
are removed. The `flatpak` binary links the patched code statically, so the
CLI alone carries every change.

## Where the code lives

The patches are developed in the fork https://github.com/flatpark/flatpak, on
branch `flatpark/<version>` (the upstream tag plus FlatPark's commits).
`debian/patches/flatpark/` is generated from it; edit the fork, then:

```sh
packages/flatpak/sync-patches.sh   # fork defaults to ../flatpak
./build.sh flatpak
```

## Moving to a new Debian version

`meta.json` sets `"update": "issue"`: an update means rebasing patches, which
the daily bot cannot do, so when `resolve-update.sh` (sid's version) moves
past the base of the changelog version, update-check opens an issue
`flatpak: <new>-N available` instead of a PR. `"publish": false` keeps the
package out of the apt repository; build it locally with `./build.sh flatpak`.
When sid moves to `<new>-N`:

1. Replace `debian/` with Debian's packaging for `<new>-N` (from
   `https://deb.debian.org/debian/pool/main/f/flatpak/flatpak_<new>-N.debian.tar.xz`),
   keeping `debian/patches/flatpark/`. Drop the `flatpak-tests` binary
   package again: its stanza in `debian/control`, `flatpak-tests.*`, and the
   autopkgtests in `debian/tests/` that depend on it.
2. In the fork: `git switch -c flatpark/<new> <new>` and cherry-pick the
   commits from the previous `flatpark/<old>` branch.
3. Prepend a `<new>-N+flatpark1` changelog entry, re-pin `meta.json`, run
   `sync-patches.sh` and `./build.sh flatpak`.

Until then sid's newer version outranks this one. To keep apt from replacing
it, pin it on the machine:

```
# /etc/apt/preferences.d/flatpak-flatpark
Package: flatpak libflatpak0 libflatpak-dev gir1.2-flatpak-1.0 flatpak-tests libflatpak-doc
Pin: version *+flatpark*
Pin-Priority: 1001
```
