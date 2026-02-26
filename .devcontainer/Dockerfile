FROM --platform=linux/amd64 nagasakah/dev-process:base

# Install pip tools
RUN pip install jsonschema pyyaml \
    && echo '--- Tool versions ---' \
    && dotnet --version \
    && node --version \
    && python3 --version \
    && uv --version \
    && yq --version \
    && aws --version \
    && terraform --version | head -1 \
    && gh --version | head -1

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

ENTRYPOINT ["start-tmux"]
