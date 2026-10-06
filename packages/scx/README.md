# scx

[sched_ext](https://github.com/sched-ext/scx) CPU schedulers (`scx_lavd`,
`scx_bpfland`, `scx_rusty`, ...) plus a simple `scx.service` driven by
`/etc/default/scx`. The `scx_loader` D-Bus daemon with `scxctl` and `scxtui`
is the separate [scx-loader](../scx-loader/) package.

The systemd unit ships **disabled**: nothing starts or switches your CPU
scheduler until you opt in.

You need a kernel with sched_ext support (>= 6.12, built with
`CONFIG_SCHED_CLASS_EXT`, e.g. XanMod). Runtime dependencies are minimal
(libc, libelf, libseccomp, zlib; libbpf is linked statically).

## Install

With the [apt.flatpark.org](../../README.md#install) source set up:

```sh
sudo apt install scx
```

## Configure

Edit `/etc/default/scx`:

```sh
SCX_SCHEDULER=scx_lavd
# SCX_FLAGS="--autopilot"        # extra flags passed to the scheduler
```

Any scheduler installed under `/usr/sbin/scx_*` works; see `scx_lavd --help`
for its flags. Then:

```sh
sudo systemctl enable --now scx
```

Use either `scx.service` or [scx-loader](../scx-loader/), not both at once.

For a quick test without any service, run a scheduler in the foreground;
`Ctrl-C` returns you to the kernel's default scheduler:

```sh
sudo scx_lavd --monitor 5
```

Status checks:

```sh
cat /sys/kernel/sched_ext/state   # enabled / disabled + loaded ops
systemctl status scx
journalctl -u scx -b
```

## Packaging notes

- Built from the upstream release tag `v<version>`. `fetch.sh` clones it, runs
  `cargo vendor` for an offline build and packs the orig tarball.
- `debian/install` is generated per release from `scheds/rust/scx_*`, so new
  or removed schedulers need no packaging edit.
- Derived from
  [sched-ext/scx-scheds-packaging-deb](https://github.com/sched-ext/scx-scheds-packaging-deb),
  adapted for the Debian toolchain: sid's `rustc`/`cargo` instead of Ubuntu's
  `rust-1.91`, `bpftool` instead of `linux-tools-*`, and LTO disabled
  (`debian/patches/0001-disable-lto.patch`) to keep link-time memory down.
- Version bumps are proposed by the daily update check but **not merged
  automatically** (`"automerge": false` in `meta.json`): a scheduler release
  is worth a look before it reaches the kernel.
