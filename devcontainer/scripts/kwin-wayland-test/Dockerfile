FROM ubuntu:26.04

# Reproducible test harness for the kdotool/KWin-Wayland resize-repaint bug.
# Runs systemd as PID 1 (sibling to tmux-restore-test/) so we get a real
# XDG_RUNTIME_DIR + D-Bus user session + logind, matching how kwin_wayland
# and kdotool actually expect to run on the host.
#
# Base image pinned to match the real host (peregrine) exactly: peregrine
# runs Ubuntu 26.04 with kwin-wayland 4:6.6.5-0ubuntu0.1 (confirmed via
# `dpkg -l | grep kwin` and `kwin_wayland --version` on peregrine itself).
# ubuntu:26.04's repos carry the identical 4:6.6.5-0ubuntu0.1 package — an
# exact version match, not just "close". Originally built against
# ubuntu:25.10 (kwin-wayland 4:6.4.5-0ubuntu3), a two-minor-version gap from
# the real host; switched after auditing harness fidelity (see README.md).

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# systemd/dbus plumbing (same baseline as tmux-restore-test), plus:
#   - kwin-wayland: the headless compositor (virtual backend is built into
#     the kwin-wayland binary itself in current Ubuntu/Debian packaging —
#     there is no separate kwin-wayland-backend-virtual package anymore)
#   - kitty: installed separately below via kovidgoyal's upstream installer,
#     matching setup.sh (apt's kitty lags upstream releases; the host runs
#     the upstream binary at ~/.local/kitty.app, which is what actually
#     matters for reproducing a kitty-Wayland rendering bug)
#   - cargo/build deps: kdotool has no Ubuntu package, built from crates.io
#   - NOTE: no screenshot tooling is installed. org.kde.KWin.ScreenShot2 is
#     NOT registered by this minimal kwin-wayland package (no kwin-data /
#     kwin-addons / effects-plugin package exists for this Ubuntu release —
#     see README.md "What we could not test"), and neither spectacle nor
#     grim/wlr-screencopy-based tools are available either (KWin doesn't
#     implement wlr-screencopy). The harness proves the bug via
#     WAYLAND_DEBUG=1 protocol tracing instead (ground truth: what buffer
#     size the client actually committed), which turned out to be more
#     precise than a screenshot diff anyway.
#     Re-checked after switching to ubuntu:26.04 (`apt-cache depends
#     kwin-wayland`): this gap is unchanged — 26.04's kwin-wayland package
#     has the same lean apt-dependency set as 25.10's, no kwin-data/
#     kwin-addons pulled in. Not a version-specific gap, a packaging
#     decision present in both releases.
RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd \
      systemd-sysv \
      dbus \
      dbus-user-session \
      libpam-systemd \
      kwin-wayland \
      qml6-module-qtquick \
      libwayland-egl1 \
      libegl-mesa0 \
      libgl1-mesa-dri \
      mesa-libgallium \
      procps \
      coreutils \
      findutils \
      grep \
      sed \
      jq \
      ca-certificates \
      sudo \
      git \
      curl \
      build-essential \
      pkg-config \
      libdbus-1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Disable services that just add boot noise / fail without real hardware.
RUN systemctl mask \
      systemd-udev-trigger.service \
      systemd-udevd.service \
      systemd-modules-load.service \
      systemd-machine-id-commit.service \
      systemd-binfmt.service \
      sys-kernel-debug.mount \
      sys-kernel-tracing.mount \
      systemd-tmpfiles-setup-dev-early.service \
      systemd-tmpfiles-setup-dev.service \
      systemd-update-utmp.service \
      systemd-update-utmp-runlevel.service \
      console-getty.service \
      getty@.service \
      getty-static.service \
    || true

# Test user matching the host UID (1000), same pattern as tmux-restore-test.
ARG TEST_USER=tester
ARG TEST_UID=1000
RUN if id -u 1000 >/dev/null 2>&1; then \
      existing=$(getent passwd 1000 | cut -d: -f1) && \
      usermod -l "$TEST_USER" -d "/home/$TEST_USER" -m "$existing" && \
      groupmod -n "$TEST_USER" "$existing"; \
    else \
      useradd -m -u "$TEST_UID" -s /bin/bash "$TEST_USER"; \
    fi && \
    echo "$TEST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$TEST_USER && \
    chmod 440 /etc/sudoers.d/$TEST_USER

# Build kdotool from source as the test user (matches how it's provisioned
# on the host: `cargo install kdotool`, not an apt package).
USER tester
ENV HOME=/home/tester
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/home/tester/.cargo/bin:${PATH}"
RUN cargo install kdotool

# kitty via upstream installer, same as setup.sh (`launch=n` skips the
# post-install kitty launch attempt, which would fail with no display yet).
RUN curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
RUN mkdir -p /home/tester/.local/bin && \
    ln -sfn /home/tester/.local/kitty.app/bin/kitty /home/tester/.local/bin/kitty && \
    ln -sfn /home/tester/.local/kitty.app/bin/kitten /home/tester/.local/bin/kitten
ENV PATH="/home/tester/.local/bin:${PATH}"

USER root

# Stage: copy harness scripts into the image
COPY harness /opt/harness
RUN chmod +x /opt/harness/*.sh

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
