FROM node:22-trixie

ARG TZ
ENV TZ="$TZ"

# Install CUDA runtime libraries (cuBLAS, cuDNN, etc.) for GPU-accelerated ML tools.
# The GPU device + driver are passed through via --device nvidia.com/gpu=all,
# but higher-level CUDA libs must be in the image.
ARG CUDA_VERSION=12-8
RUN echo "deb [trusted=yes] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" \
    > /etc/apt/sources.list.d/cuda.list && \
  apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-${CUDA_VERSION} \
    libcudnn9-cuda-12 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install basic development tools, iptables/ipset, and Docker
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  postgresql-client \
  python3 \
  python3-dev \
  python3-pip \
  rsync \
  wl-clipboard \
  neovim \
  locales \
  imagemagick \
  docker.io \
  && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
  && locale-gen \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Allow pip install without --break-system-packages (build-time and runtime)
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Install rstring package
RUN pip3 install rstring

# Install Google Cloud CLI
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && apt-get install -y --no-install-recommends google-cloud-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Doppler CLI
RUN curl -fsSL https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key | gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" > /etc/apt/sources.list.d/doppler-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends doppler && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Playwright system deps (X11 libs, fonts, xvfb) and Chromium browser
# Browsers go to /opt/playwright (not ~/.cache) because the home dir bind mount
# shadows the image's /home/node at runtime.
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
RUN npx playwright install-deps && \
  mkdir -p /opt/playwright && \
  npx playwright install chromium && \
  chown -R node:node /opt/playwright

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
# Note: .config must be created here so bind mounts for subdirs (git, gh, gcloud) don't make it root-owned
RUN mkdir -p /workspace /home/node/.claude /home/node/.config && \
  chown -R node:node /workspace /home/node/.claude /home/node/.config

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install bun with proper PATH setup
ENV BUN_INSTALL=/home/node/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash && \
    # Add to shell configs for interactive sessions
    echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.zshrc && \
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.zshrc && \
    echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc && \
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc && \
    # Verify bun is installed
    $BUN_INSTALL/bin/bun --version

# Install Poetry via pip (the official installer puts it in ~/.local which
# gets shadowed by the home dir bind mount)
ENV PATH="/home/node/.local/bin:$PATH"
USER root
RUN pip3 install poetry && poetry --version
USER node

# Install Rust using rustup (official installer)
ENV CARGO_HOME=/home/node/.cargo
ENV RUSTUP_HOME=/home/node/.rustup
ENV PATH=$CARGO_HOME/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    # Add to shell configs for interactive sessions
    echo 'export CARGO_HOME="$HOME/.cargo"' >> ~/.zshrc && \
    echo 'export RUSTUP_HOME="$HOME/.rustup"' >> ~/.zshrc && \
    echo 'export PATH="$CARGO_HOME/bin:$PATH"' >> ~/.zshrc && \
    echo 'export CARGO_HOME="$HOME/.cargo"' >> ~/.bashrc && \
    echo 'export RUSTUP_HOME="$HOME/.rustup"' >> ~/.bashrc && \
    echo 'export PATH="$CARGO_HOME/bin:$PATH"' >> ~/.bashrc && \
    # Verify rust is installed
    $CARGO_HOME/bin/rustc --version && \
    $CARGO_HOME/bin/cargo --version

# Install pnpm
RUN npm install -g pnpm

# Install LSP language servers for Claude Code intelligence
RUN npm install -g typescript-language-server typescript pyright

# Install Playwright MCP server (browser already installed above)
RUN npm install -g @playwright/mcp

# Install Claude Code (native installer puts it in ~/.local which gets
# shadowed by the home dir bind mount — copied to /usr/local/bin below)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install gemini-cli (auto-update disabled via settings — it breaks npm-global
# installs inside containers because the restarted process can't resolve its module)
RUN npm install -g @google/gemini-cli

# Install codex-cli
RUN npm install -g @openai/codex

# Install kimi-cli (Moonshot AI) — needs Python >=3.12 but Bookworm ships 3.11.
# uv downloads a standalone Python 3.12 and creates an isolated venv.
# UV_TOOL_DIR/UV_TOOL_BIN_DIR put the venv and shim in system paths accessible to all users.
USER root
RUN curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh && \
    UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin UV_PYTHON_INSTALL_DIR=/opt/uv-python \
    /root/.local/bin/uv tool install kimi-cli --python 3.12 && \
    chmod -R o+rX /opt/uv-tools /opt/uv-python
USER node

# Install Vercel CLI
RUN npm install -g vercel

# Install Prisma CLI
RUN npm install -g prisma

# Install Sentry CLI
RUN npm install -g @sentry/cli

# Install PostHog CLI
RUN npm install -g @posthog/cli

# Copy binaries that native installers put under ~/.local or ~/.bun to a
# system path — the home dir bind mount shadows the image's /home/node/.
USER root
RUN for pair in \
      "/home/node/.bun/bin/bun:bun" \
      "/home/node/.local/bin/claude:claude"; \
    do \
      src="${pair%%:*}"; name="${pair##*:}"; \
      real="$(readlink -f "$src" 2>/dev/null || true)"; \
      if [ -f "$real" ]; then \
        cp "$real" "/usr/local/bin/$name"; \
      else \
        echo "ERROR: Expected $name at $src but not found. Installer may have changed layout." >&2; exit 1; \
      fi; \
    done
USER node

# Disable gemini-cli auto-update (breaks npm-global installs in containers)
RUN mkdir -p /home/node/.gemini && \
  echo '{"general":{"disableAutoUpdate":true}}' > /home/node/.gemini/settings.json

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

# Add node user to docker group for DinD access
RUN usermod -aG docker node
USER node
