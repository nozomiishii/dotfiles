FROM mcr.microsoft.com/devcontainers/typescript-node:4-22-bookworm@sha256:e3a386f77bc75f55cd8512de30b761df1d9f36317d0b1bebd897f0a76b55db3d

# Enable corepack for pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /workspace

# Add labels for better image management
LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
