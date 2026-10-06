# strata

[Strata](https://github.com/lgse/strata): a fast, keyboard-first GTK 4 file
manager with Miller columns and inline previews.

This is the official upstream release binary, repackaged unmodified:
`/usr/bin/strata` is byte-identical to the file in the release tarball, so
`gh attestation verify` still matches it.

## Install

```sh
sudo apt install strata
```

`Depends` holds only the shared libraries the binary links (GTK 4,
GtkSourceView 5, GStreamer, Poppler GLib, ...). Everything else is optional:

| Recommends | For |
| --- | --- |
| `bubblewrap` | Image, PDF, media and archive previews. Strata renders them inside a bwrap sandbox and shows "Preview unavailable" without it. |
| `gvfs` | Trash, the Devices list and network locations. |
| `gstreamer1.0-plugins-base`, `-good` | Audio and video playback in previews. |

`apt install --no-install-recommends strata` skips all of them.
`Suggests` adds `ffmpeg`/`ffmpegthumbnailer` (video thumbnails),
`imagemagick`/`libraw-bin` (RAW images), `gvfs-backends` (SMB, SFTP),
`gstreamer1.0-libav`, `squashfs-tools` (AppImage icons) and
`xdg-terminal-exec`.

## Make Strata the default file manager (optional)

Installing the package does not change your file manager. Upstream ships a
D-Bus activation file for `org.freedesktop.FileManager1`; the package keeps it
as an inactive template. To opt in for your user:

```sh
mkdir -p ~/.local/share/dbus-1/services
cp /usr/share/strata/io.github.lgse.Strata.FileManager1.service ~/.local/share/dbus-1/services/
```

## Updates

Through apt. The in-app update check is off by default; leave it off, because
`/usr/bin/strata` belongs to the package. Upstream's install-source marker
(which tells Strata who manages it) is defined for their AUR packages only and
its docs ask other packages not to reuse it, so this package does not ship
one.

New stable releases are picked up by the daily update check, built,
install-tested and merged automatically (`"automerge": true` in
`meta.json`). Nightly and preview builds are not packaged.

## Packaging notes

- `meta.json` pins the x86_64 release tarball (URL + sha256); `fetch.sh`
  verifies it and unpacks it as the source tree. Nothing is compiled.
- `debian/rules` skips `dh_strip` and `dh_dwz` to keep the binary
  byte-identical. The runtime libraries are listed in Build-Depends only so
  `dh_shlibdeps` can compute `Depends`.
- FlatPark also publishes Strata as a Flatpak (`io.github.lgse.Strata`). That
  build cannot show image, PDF, media or archive previews, because Flatpak
  forbids the nested bwrap sandbox Strata needs. This package can.
