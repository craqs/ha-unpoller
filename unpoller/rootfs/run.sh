#!/usr/bin/env bashio
# ==============================================================================
# UniFi Poller (unpoller) add-on entrypoint.
#
# Renders an unpoller config from the add-on options into a tmpfs file and
# exec's the binary. Serves Prometheus metrics on :9130. The config (incl. the
# UniFi password) lives only at /tmp/up.conf in the container's tmpfs — the
# password is supplied via the add-on options.
# ==============================================================================
set -e

url="$(bashio::config 'controller_url')"
user="$(bashio::config 'unifi_user')"
pass="$(bashio::config 'unifi_pass')"
verify_ssl="false"
bashio::config.true 'verify_ssl' && verify_ssl="true"

if bashio::var.is_empty "${user}" || bashio::var.is_empty "${pass}"; then
    bashio::exit.nok 'unifi_user / unifi_pass are required — set a read-only, site-local UniFi account in the add-on options.'
fi

conf="/tmp/up.conf"
# Owner-only perms before writing the password.
( umask 077; : > "${conf}" )
cat > "${conf}" <<EOF
[poller]
  debug = false
[prometheus]
  disable = false
  http_listen = "0.0.0.0:9130"
  report_errors = false
[influxdb]
  disable = true
[unifi]
  dynamic = false
  [unifi.defaults]
    role = "default"
    url = "${url}"
    user = "${user}"
    pass = "${pass}"
    sites = ["all"]
    verify_ssl = ${verify_ssl}
    # Trim polling to device/per-port data. unpoller still emits per-client
    # series; drop those at scrape time in Prometheus if you don't need them.
    save_sites = false
    save_dpi = false
    save_ids = false
    save_events = false
    save_alarms = false
    save_anomalies = false
EOF

bashio::log.info "Starting unpoller → ${url} (Prometheus :9130)"
exec /usr/local/bin/unpoller --config "${conf}"
