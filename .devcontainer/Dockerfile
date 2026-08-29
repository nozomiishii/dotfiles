FROM mcr.microsoft.com/devcontainers/base:bookworm@sha256:73d85a96694a2cadca1ba3fcb5721f2312a64f1d571dd86f6c77e10a708931dc

# node と pnpm の版は mise.toml / mise.lock だけが持つ。この Dockerfile には書かない
# renovate: datasource=github-releases depName=jdx/mise
ARG MISE_VERSION=v2026.8.14

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# shims 経由でツールを引く https://mise.jdx.dev/dev-tools/shims.html
ENV PATH="/home/vscode/.local/share/mise/shims:/home/vscode/.local/bin:${PATH}" \
    MISE_TRUSTED_CONFIG_PATHS=/workspaces

# login shell は /etc/profile が PATH を組み直すため、ENV とは別に profile.d からも通す
RUN echo "export PATH=\"/home/vscode/.local/share/mise/shims:\$PATH\"" > /etc/profile.d/10-mise-shims.sh

USER vscode

# ビルド時に mise.toml を解決してツールをイメージへ焼き込む。
# mise.lock があるので checksum 検証付きで入る
COPY --chown=vscode:vscode mise.toml mise.lock /tmp/mise-bootstrap/
RUN curl -fsSL https://mise.run | MISE_VERSION="${MISE_VERSION}" MISE_INSTALL_PATH=/home/vscode/.local/bin/mise sh \
    && mise trust /tmp/mise-bootstrap/mise.toml \
    && mise --cd /tmp/mise-bootstrap install \
    && rm -rf /tmp/mise-bootstrap

LABEL org.opencontainers.image.source="https://github.com/nozomiishii/dotfiles"
