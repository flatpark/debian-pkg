# scx-loader

[scx_loader](https://github.com/sched-ext/scx-loader): a D-Bus daemon that
starts, stops and switches [sched_ext](../scx/) schedulers, with the `scxctl`
CLI and the `scxtui` terminal UI. Depends on the [scx](../scx/) package for
the schedulers themselves.

The `scx_loader.service` unit ships **disabled**.

## Install

```sh
sudo apt install scx-loader
```

## Configure

Edit `/etc/scx_loader.toml`:

```toml
default_sched = "scx_lavd"
default_mode  = "Auto"     # Auto | Gaming | LowLatency | PowerSave | Server

# per-scheduler flags per mode:
# [scheds.scx_lavd]
# gaming_mode = ["--performance"]
```

`scxctl list` shows the schedulers the loader knows about. A few in-tree
schedulers (`scx_layered`, `scx_mitosis`) are not wired into the loader and
are only available through `scx.service` (see [scx](../scx/)). Use one
mechanism or the other, not both at once.

```sh
sudo systemctl enable --now scx_loader
scxctl get                 # current scheduler + mode
scxctl switch scx_bpfland
scxctl stop
scxtui                     # scheduler list, status, logs
journalctl -u scx_loader -b
```

## Packaging notes

- Built from the upstream release tag `v<version>` with every crate vendored
  (same `fetch.sh` path as [scx](../scx/)). `scx_loader`, `scxctl` and
  `scxtui` moved out of the main scx tree in v1.1.x.
- The upstream default config is installed as the vendor default
  (`/usr/share/scx_loader/config.toml`); `/etc/scx_loader.toml` is a conffile
  for local overrides.
- Version bumps wait for review (`"automerge": false`).
