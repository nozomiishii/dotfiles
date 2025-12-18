FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:9add39631671c93a836f678b6c11d5ba759b21204f8604619ed1674b5f874f70

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
