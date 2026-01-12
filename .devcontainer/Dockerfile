# Dockerfile for C201 kernel development environment
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies and cross-compilation toolchain
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    wget \
    curl \
    git \
    vim \
    nano \
    make \
    sudo \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-completions \
    zsh-history-substring-search \
    zsh-history-substring-search-highlighting \
    zsh-history-substring-search-autosuggestions \
    zsh-history-substring-search-syntax-highlighting \
    kmod \
    cpio \
    xz-utils \
    python3 \
    python3-pip \
    device-tree-compiler \
    u-boot-tools \
    && rm -rf /var/lib/apt/lists/*

# Create vscode user (Codespaces will use this)
RUN useradd -m -s /bin/bash vscode && \
    usermod -aG sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    chsh -s /bin/zsh vscode && chsh -s /bin/zsh root
RUN chsh -s /bin/zsh vscode && chsh -s /bin/zsh root

# Set up environment variables
ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabihf-
ENV PATH="/usr/local/bin:${PATH}"

# Set working directory
WORKDIR /workspace

# Switch to vscode user
USER vscode
