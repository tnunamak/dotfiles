FROM ubuntu:25.10

# Reproducible test harness for the tmux-resurrect post-crash recovery flow.
# Runs systemd as PID 1 so we can exercise tmux.service / tmux-restore.service
# in the same execution context as the host.

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Match host tooling: tmux, git, zsh, systemd, plus the few utilities the
# tmux-resurrect/continuum/our-scripts pipeline relies on (find, sort, awk,
# grep, mapfile-capable bash, mktemp).
RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd \
      systemd-sysv \
      dbus \
      dbus-user-session \
      tmux \
      git \
      zsh \
      bash \
      coreutils \
      findutils \
      gawk \
      grep \
      sed \
      procps \
      ca-certificates \
      sudo \
      jq \
      curl \
      stow \
      libpam-systemd \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Disable services that just add boot noise / fail in a container without
# real hardware. We only care about the tmux units we install.
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

# Test user matching the host UID (1000) so paths and ownership line up
# with the bind-mounted dotfiles repo.
# Ubuntu ships with a default 'ubuntu' user at UID 1000. Rename it to 'tester'
# so paths and ownership match the host UID without UID conflicts.
ARG TEST_USER=tester
ARG TEST_UID=1000
RUN if id -u 1000 >/dev/null 2>&1; then \
      existing=$(getent passwd 1000 | cut -d: -f1) && \
      usermod -l "$TEST_USER" -d "/home/$TEST_USER" -m "$existing" && \
      groupmod -n "$TEST_USER" "$existing"; \
    else \
      useradd -m -u "$TEST_UID" -s /usr/bin/zsh "$TEST_USER"; \
    fi && \
    chsh -s /usr/bin/zsh "$TEST_USER" && \
    echo "$TEST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$TEST_USER && \
    chmod 440 /etc/sudoers.d/$TEST_USER

# Stage 1: copy the harness scripts into the image
COPY harness /opt/harness
RUN chmod +x /opt/harness/*.sh

# systemd as PID 1
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
