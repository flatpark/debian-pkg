# dae

[dae](https://github.com/daeuniverse/dae): an eBPF-based transparent proxy.
Traffic is split in the kernel, so direct connections never pass through
userspace; rules match by process, domain, IP and MAC.

This is the official upstream release (`dae-linux-x86_64.tar.xz`, the
baseline amd64 build), repackaged unmodified: `/usr/bin/dae`, the systemd
unit, the example config and the bundled v2fly `geoip.dat`/`geosite.dat` are
byte-identical to the tarball.

## Install

```sh
sudo apt install dae
```

Needs a kernel with BTF and eBPF (5.17+; any sid kernel qualifies).

## Set up

Installing does **not** enable or start the service: `dae.service` runs
`/etc/dae/config.dae`, which you write first. dae refuses a config that is
group-writable or readable by others, so keep it 0600/0640:

```sh
sudo install -m 600 /etc/dae/example.dae /etc/dae/config.dae
sudoedit /etc/dae/config.dae          # subscriptions/nodes, routing, lan/wan interface
sudo dae validate -c /etc/dae/config.dae
sudo systemctl enable --now dae
```

`systemctl reload dae` applies config changes without dropping connections.
See upstream's [docs](https://github.com/daeuniverse/dae/tree/main/docs) for
the config reference.

## Updates

Through apt. Once the service is enabled, a package upgrade restarts it
(briefly interrupting proxied traffic); a disabled, stopped service stays
that way.

The daily update check picks up new stable releases, builds and
install-tests them (`dae validate` against the shipped example), but they
wait for review (`"automerge": false` in `meta.json`): dae is a network
daemon that restarts on upgrade, and upstream occasionally changes config
syntax.

`geoip.dat`/`geosite.dat` are the copies bundled with each upstream release
and are refreshed only with it. To track newer data, put your own files in
`/usr/local/share/dae/`, which is earlier in dae's search path
(`$XDG_DATA_DIRS`) than `/usr/share/dae/`.

## Packaging notes

- `meta.json` pins the x86_64 release tarball (URL + sha256); `fetch.sh`
  verifies it and unpacks it as the source tree. Nothing is compiled.
- `debian/rules` skips `dh_strip`/`dh_dwz` to keep the binary byte-identical,
  installs the unit with `--no-enable`, and restores upstream's 0640 on
  `/etc/dae/example.dae` (a conffile) after `dh_fixperms`.
- Upstream also publishes `x86_64_v2_sse` and `x86_64_v3_avx2` builds; the
  baseline is packaged so it runs on any amd64 machine.
