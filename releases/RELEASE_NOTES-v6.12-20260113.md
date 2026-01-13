# Release Notes - v6.12-20260113

## C201 Kernel for Gentoo Linux

**Release Date**: Tue, 13 Jan 2026 09:20:41 +0000  
**Kernel Version**: 6.12  
**Target Device**: ASUS Chromebook C201 (rk3288 veyron-speedy)

## What's Included

This release contains a pre-built Linux kernel for the ASUS Chromebook C201 running Gentoo Linux.

### Files

- `zImage` - Kernel image (6.12)
- `rk3288-veyron-speedy.dtb` - Device tree blob
- `kernel.config` - Kernel configuration
- `c201-system-v6.12-20260113.img` - Full system image (4GB) with kernel and rootfs

## Features

- Linux kernel 6.12
- Optimized for rk3288-veyron-speedy (ASUS Chromebook C201)
- NETFILTER support (iptables, nftables)
- BTRFS filesystem support
- CRYPTO libraries support
- All required drivers for C201 hardware

## Installation

See `README.md` in the package for installation instructions.

## Verification

After installation, verify the kernel:
```bash
uname -r
```

Should display: `6.12`

## Build Information

- **Cross Compiler**: arm-linux-gnueabihf-gcc
- **Build Host**: codespaces-3081e1
- **Build Date**: Tue, 13 Jan 2026 09:20:41 +0000

## Source Code

The kernel source and build configuration are available in this repository.
To build from source, follow the instructions in `README.md`.

## Previous Releases

See GitHub Releases for previous versions.
