FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04@sha256:e57fdff274ed0bac0776490fa2644c242491bb21d4df7ad0bb79b433eac5168d

# Use the non-root user that is pre-created in the devcontainers base image
ARG USERNAME=vscode
USER ${USERNAME}

# Configure pnpm environment for the chosen user
ENV PNPM_HOME="/home/${USERNAME}/.local/share/pnpm"
ENV PATH="${PNPM_HOME}:$PATH"

RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
