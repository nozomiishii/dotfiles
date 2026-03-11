FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:7653612ebf9384fa1cbd32413d8f4fbf7daaf24e39e8664d9fc030de8c0c0af2

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
