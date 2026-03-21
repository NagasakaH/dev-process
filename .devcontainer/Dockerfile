FROM --platform=linux/amd64 nagasakah/dev-process:base

# Install tini for proper PID 1 zombie reaping
RUN apt-get update && apt-get install -y --no-install-recommends tini && rm -rf /var/lib/apt/lists/*

# Build tmux 3.6a from source
RUN apt-get update && apt-get install -y --no-install-recommends \
      libevent-dev ncurses-dev build-essential bison pkg-config \
    && cd /tmp \
    && curl -fsSL https://github.com/tmux/tmux/releases/download/3.6a/tmux-3.6a.tar.gz | tar xz \
    && cd tmux-3.6a \
    && ./configure && make -j$(nproc) && make install \
    && cd / && rm -rf /tmp/tmux-3.6a \
    && apt-get purge -y build-essential bison && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright CLI globally
RUN npm install -g playwright && npx playwright install-deps 2>/dev/null || true

# Install pip tools
RUN pip install jsonschema pyyaml
# RHEL でdindが動かない問題を修正
RUN update-alternatives --set iptables /usr/sbin/iptables-nft && update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

# -------------------------------------------------------------------
# Embedded dotfiles & scripts
# -------------------------------------------------------------------

# tmux config
COPY dotfiles/.tmux.conf /home/vscode/.tmux.conf
COPY dotfiles/.config/tmux/cheatsheet.txt /home/vscode/.config/tmux/cheatsheet.txt

# cplt command
COPY scripts/cplt /usr/local/bin/cplt

# start-tmux entrypoint
COPY scripts/start-tmux.sh /usr/local/bin/start-tmux

RUN chmod +x /usr/local/bin/cplt /usr/local/bin/start-tmux \
    && chown -R vscode:vscode /home/vscode/.tmux.conf /home/vscode/.config/tmux
ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["tini", "--", "start-tmux"]
