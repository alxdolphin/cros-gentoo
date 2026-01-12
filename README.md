# C201 Kernel Development

Kernel configuration and build environment for ASUS Chromebook C201 (rk3288 veyron-speedy) running Gentoo Linux.

## Usage

### GitHub Codespace

1. Create repository from this codebase
2. Open Codespace: navigate to Code → Codespaces → Create codespace
3. Setup kernel source: `scripts/setup-kernel-source.sh`
4. Build kernel: `scripts/build-kernel.sh`
5. Package kernel: `scripts/package-kernel.sh`

### Local Development

Install dependencies:
```bash
sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf bc bison flex libssl-dev libelf-dev \
    device-tree-compiler
```

Set environment:
```bash
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
```

## Project Structure

```
.devcontainer/     # Codespace configuration
docs/              # Documentation
kernel/            # Kernel configs and build artifacts
scripts/           # Build scripts
linux/             # Kernel source (git submodule)
.config.running    # Default kernel configuration
```

## Kernel Configuration

Using menuconfig:
```bash
cd linux && make menuconfig
```

Using existing config:
```bash
cp .config.running linux/.config
cd linux && make olddefconfig
```

## Build Process

```bash
scripts/build-kernel.sh
```

Output in `kernel/`:
- `zImage` - Kernel image
- `rk3288-veyron-speedy.dtb` - Device tree
- `config-latest` - Kernel configuration

Package for deployment:
```bash
scripts/package-kernel.sh
```

## Environment Variables

- `ARCH=arm` - Target architecture
- `CROSS_COMPILE=arm-linux-gnueabihf-` - Cross-compiler prefix
- `KERNEL_VERSION=v6.12` - Kernel version tag (default, used for git submodule)

## Documentation

- `docs/DEVELOPMENT-WORKFLOW.md` - Complete development workflow
- `docs/CODESPACE-SETUP.md` - Codespace configuration
- `docs/KERNEL-BUILD.md` - Build and deployment
- `docs/BOOT-INSTRUCTIONS.md` - C201 boot process
- `docs/NBD-SETUP.md` - Network block device
- `docs/PRECONFIGURED-IMAGE.md` - Recovery image information
