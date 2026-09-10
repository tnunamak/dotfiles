# Must match the host release (26.04 resolute). On 25.10/questing, gcr4 is
# 4.4.0.1-7, whose socket unit declares only `After=gpg-agent-ssh.socket` —
# it does NOT order itself after ssh-agent.socket, so the two ExecStartPost
# lines race and the baseline cell cannot reproduce the host's contention.
# 26.04 ships 4.4.0.1-8, which added `After=ssh-agent.socket`.
FROM ubuntu:26.04

# Harness for the SSH_AUTH_SOCK election: does our environment.d pin plus the
# gcr-ssh-agent.socket drop-in survive a COLD START of the systemd user manager?
#
# The live-host check can only restart the gcr socket inside an already-running
# user manager. That does not exercise the ordering that matters at login:
# environment generators run once when user@UID.service starts, and socket
# units activate afterwards. Here the user manager is started from scratch by
# logind, so the generator and the socket run in their real order.
#
# Runs systemd as PID 1, same as devcontainer/scripts/tmux-restore-test.

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# gcr4 provides gcr-ssh-agent.socket/.service — the unit we are contending
# with. openssh-client provides ssh-agent.socket, ssh-add and ssh-keygen.
RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd \
      systemd-sysv \
      dbus \
      dbus-user-session \
      libpam-systemd \
      openssh-client \
      gcr4 \
      bash \
      coreutils \
      grep \
      sed \
      procps \
      sudo \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN systemctl mask \
      systemd-udev-trigger.service \
      systemd-udevd.service \
      systemd-modules-load.service \
      systemd-machine-id-commit.service \
      systemd-binfmt.service \
      systemd-tmpfiles-setup-dev-early.service \
      systemd-tmpfiles-setup-dev.service

# Ubuntu ships a default user at UID 1000; rename it rather than colliding.
# Same approach as devcontainer/scripts/tmux-restore-test/Dockerfile.
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

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
