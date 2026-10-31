# syntax=docker/dockerfile:1
# Node.js 24 LTS を Ubuntu 24.04 に導入するマルチステージビルド。
# Docker がホスト (Intel / Apple Silicon) に合わせて適切なアーキテクチャを選びます。
FROM node:24-bookworm-slim AS node-runtime

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        jq \
        less \
        libstdc++6 \
        openssh-client \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Node.js と npm を公式 Node イメージから導入。
COPY --from=node-runtime /usr/local/ /usr/local/

# Codex CLI を全ユーザー共通の領域にインストール。
RUN npm install --global @openai/codex \
    && npm cache clean --force \
    && groupadd --gid 10001 codex \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash codex \
    && mkdir -p /home/codex/.codex /workspaces/codex-learning/workspace \
    && chown -R codex:codex /home/codex /workspaces/codex-learning

ENV HOME=/home/codex \
    CODEX_HOME=/home/codex/.codex \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

# root では実行しない。
USER codex
WORKDIR /workspaces/codex-learning/workspace

# VS Code Dev Containers から接続するためコンテナを維持する。
CMD ["sleep", "infinity"]
