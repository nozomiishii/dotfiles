FROM mcr.microsoft.com/devcontainers/typescript-node:3-22-bookworm@sha256:df90a1e397d6096285b6e0ae804c20f7c26a2234eb50245502993cf9bd1fa9e3

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
