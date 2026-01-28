FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:531dd39706fc0cfca5011ac6fc378fe3ae73bcf66a7f97b2def8a33b1eab17b3

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
