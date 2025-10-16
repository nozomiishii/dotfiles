FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:e83fd95d62246ef128dccc719461b61bbb8eaaf016ed678161a2a5f33a547c10

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
