# ha-unpoller — UniFi Poller add-on for Home Assistant

A Home Assistant add-on that runs [unpoller](https://github.com/unpoller/unpoller)
in Prometheus mode, exporting UniFi controller metrics — **per-port link speed**,
device CPU/mem/temperature, uptime, client counts, PoE, and RX/TX throughput — on
`:9130` for a Prometheus server to scrape.

A common use is catching wired links that silently negotiate down from 1 Gbps
(e.g. a faulty cable) via the `unpoller_device_port_port_speed_bps` metric, plus
general device-health dashboards.

## Install

1. Home Assistant → **Settings → Add-ons → Add-on Store**.
2. Top-right **⋮ → Repositories** → add `https://github.com/craqs/ha-unpoller` → **Add** → **Close**.
3. Refresh the store, open **"UniFi Poller (unpoller)"** → **Install**.
4. **Configuration** tab:
   - `controller_url`: your local controller, e.g. `https://192.168.1.1`.
   - `unifi_user` / `unifi_pass`: a **dedicated, read-only, local** UniFi account
     (UniFi console → Admins → add a *Local* admin with the *View Only* role).
     Don't use a cloud SSO account or a full-admin account. There is no default
     password — the add-on refuses to start until you set one.
   - `verify_ssl`: leave `false` (UniFi controllers use a self-signed cert).
5. **Info** tab: **Protection mode can stay ON** — this add-on needs no host PID or
   host network. Turn **ON** "Start on boot" and "Watchdog". Start it, check the
   **Log** tab for a clean start, then open `http://<ha-host>:9130/metrics` and
   confirm `unpoller_device_port_port_speed_bps` appears.

> The UniFi password lives only in the add-on options on this appliance. Rotate it
> by changing it in the UniFi console and updating the add-on option.

## Security & supply chain

- The metrics endpoint binds `0.0.0.0:9130`, so it is reachable on the local
  network without authentication. If that isn't acceptable for your setup, unpoller
  supports HTTP basic auth — restrict access at the network/firewall level as
  appropriate.
- The image is built from the **official `ghcr.io/unpoller/unpoller` image pinned by
  digest** (multi-stage copy of the verified binary), published to
  `ghcr.io/craqs/ha-unpoller-<arch>`. Renovate bumps the upstream digest and the
  add-on `version` in lockstep; GitHub Actions are SHA-pinned; CI runs a pinned
  Trivy scan.

## Layout

| Path | Purpose |
|---|---|
| `unpoller/config.yaml` | Add-on manifest (options/schema, ports, `version`) |
| `unpoller/Dockerfile` | Multi-stage build copying the pinned unpoller binary |
| `unpoller/build.yaml` | Per-arch HA base image |
| `unpoller/rootfs/run.sh` | Entrypoint — renders the unpoller config and exec's it |
| `.github/workflows/build.yaml` | Build + push to GHCR + Trivy scan |
| `renovate.json` | Lockstep version/digest bumps, Action digest pinning |
