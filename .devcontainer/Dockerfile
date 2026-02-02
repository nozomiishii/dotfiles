FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:1ce9407fc8ad4ecc6513cda627aa4a2b74b0a2557baf0ccb07a1287cf1deb154

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
