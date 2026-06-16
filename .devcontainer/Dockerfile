FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:59e8c044af4ed4795967188c3d0b9bc677f42d42b0ff41f98c8be5333defeb64

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
