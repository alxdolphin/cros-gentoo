# Development Workflow

Complete workflow for C201 kernel development using GitHub Codespaces.

## Initial Setup

### Repository Setup

```bash
# Clone repository
git clone <repository-url>
cd c201-usb

# Initialize git submodule for kernel source
git submodule update --init --recursive linux
```

### Codespace Setup

1. Open repository in GitHub
2. Navigate to Code → Codespaces → Create codespace
3. Wait for container to build (includes cross-compilation toolchain)

### Kernel Source Setup

```bash
# Initialize kernel submodule (if not already done)
scripts/setup-kernel-source.sh
```

This will:
- Initialize git submodule pointing to Linux kernel repository
- Checkout configured kernel version (default: v6.12)
- Copy `.config.running` to `linux/.config` if needed

## Kernel Configuration

### Default Configuration

The default kernel configuration is `.config.running` which includes:
- NETFILTER support (iptables, nftables)
- BTRFS filesystem support
- CRYPTO libraries support
- All required drivers for C201 (rk3288 veyron-speedy)

### Using Default Config

```bash
cp .config.running linux/.config
cd linux
make olddefconfig
```

### Customizing Configuration

```bash
cd linux
make menuconfig
# Make your changes
make savedefconfig
cp defconfig ../kernel/.config-custom
```

### Updating Default Config

After testing a custom configuration:

```bash
# Copy tested config to default
cp linux/.config .config.running
cp .config.running kernel/.config
cp .config.running kernel-config
```

## Building Kernel

### Quick Build

```bash
scripts/build-kernel.sh
```

This script:
1. Checks for cross-compiler
2. Copies `.config.running` to `linux/.config` if needed
3. Runs `make olddefconfig` to update config
4. Builds kernel, device tree, and modules
5. Copies artifacts to `kernel/` directory

### Manual Build

```bash
cd linux
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
make olddefconfig
make -j$(nproc) zImage dtbs modules
```

## Packaging and Deployment

### Package Kernel

```bash
scripts/package-kernel.sh
```

Creates `kernel-package/` with:
- `zImage` - Kernel image
- `rk3288-veyron-speedy.dtb` - Device tree
- `kernel.config` - Configuration used
- `PACKAGE_INFO.txt` - Build information

### Deploy to C201

See `docs/KERNEL-BUILD.md` for deployment methods:
- USB/SD card
- NFS
- NBD

## Configuration Files

| File | Purpose |
|------|---------|
| `.config.running` | Source of truth, default kernel configuration |
| `kernel/.config` | Copy used for builds (synced from `.config.running`) |
| `kernel-config` | Gentoo kernel config path (synced from `.config.running`) |

## Git Submodule Management

### Update Kernel Version

```bash
cd linux
git fetch
git checkout v6.13  # or desired version
cd ..
git add linux
git commit -m "feat: update kernel to v6.13"
```

### Sync Submodule

```bash
git submodule update --remote linux
```

## Troubleshooting

### Submodule Not Initialized

```bash
git submodule update --init --recursive linux
```

### Config Out of Sync

```bash
# Sync all config files
cp .config.running kernel/.config
cp .config.running kernel-config
```

### Build Fails

1. Check cross-compiler: `arm-linux-gnueabihf-gcc --version`
2. Verify config: `ls -la .config.running`
3. Clean build: `cd linux && make clean`
4. Rebuild: `scripts/build-kernel.sh`
