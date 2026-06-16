# syntax=docker/dockerfile:1
# BUILD_FROM (the per-arch HA base, injected by home-assistant/builder) must be a
# global ARG — declared before any FROM — to be usable in the second FROM below.
ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.22
# ──────────────────────────────────────────────────────────────────────────────
# Stage 1: pull the unpoller binary from the official upstream image, pinned by
# digest. Using the upstream image (not a re-downloaded tarball) means the
# artifact is verified by content digest. Renovate's native docker manager bumps
# this tag AND digest together, so the supply-chain pin stays intact; the add-on
# `version` in config.yaml is bumped in lockstep via the customManager in
# ../renovate.json (same depName) so Home Assistant surfaces every bump.
# ──────────────────────────────────────────────────────────────────────────────
FROM ghcr.io/unpoller/unpoller:v3.3.0@sha256:1c03bc25d83c5dde54e7436a010851d2db4831f8afe4f2ee60699d52dd01c5c4 AS upstream

# ──────────────────────────────────────────────────────────────────────────────
# Stage 2: the Home Assistant add-on image.
# ──────────────────────────────────────────────────────────────────────────────
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy the verified unpoller binary out of the pinned upstream image. The
# official image's entrypoint is /usr/bin/unpoller.
COPY --from=upstream /usr/bin/unpoller /usr/local/bin/unpoller
RUN chmod +x /usr/local/bin/unpoller

COPY rootfs /
RUN chmod a+x /run.sh

LABEL \
    io.hass.type="addon" \
    org.opencontainers.image.source="https://github.com/craqs/ha-unpoller"

# No S6-Overlay: run.sh is a thin wrapper that exec's the unpoller binary.
ENTRYPOINT []
CMD ["/run.sh"]
