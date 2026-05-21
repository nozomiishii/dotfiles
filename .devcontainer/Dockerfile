FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:03975b6968e9a3bf55438dd8b9a882c8af5821da9d512e28ae3c4a6ce690f244

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
