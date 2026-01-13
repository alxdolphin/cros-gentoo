# Dockerfile for C201 kernel development environment
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies and cross-compilation toolchain
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    make \
    bc \
    bison \
    flex \
    # ARM cross-compilation toolchain
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    # Kernel build dependencies
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    # Device tree and bootloader tools
    device-tree-compiler \
    u-boot-tools \
    # Kernel utilities
    kmod \
    cpio \
    xz-utils \
    # Development tools
    git \
    wget \
    curl \
    vim \
    nano \
    # Python for kernel scripts
    python3 \
    python3-pip \
    # System utilities
    sudo \
    # Shell (zsh optional, bash is default)
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-completions \
    && rm -rf /var/lib/apt/lists/*

# Create vscode user with sudo access (Codespaces default)
RUN useradd -m -s /bin/bash vscode && \
    usermod -aG sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up environment variables for kernel building
ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabihf-
ENV PATH="/usr/local/bin:${PATH}"

# Create workspace directory and set ownership to vscode user
# This ensures vscode has write permissions when the container starts
RUN mkdir -p /workspace && \
    chown -R vscode:vscode /workspace

# Set working directory
WORKDIR /workspace

# Note: Do not switch to vscode user here - devcontainer features need to run as root
# The devcontainer.json remoteUser setting will handle switching to vscode after features install
