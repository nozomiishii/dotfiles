FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:c4b7b87ff47b18de2116eb0b0aab7f621a8c5639eaae65e8e123a62450c7837e

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
