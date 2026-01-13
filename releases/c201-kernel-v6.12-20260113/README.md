# C201 Kernel Release v6.12-20260113

Kernel image for ASUS Chromebook C201 (rk3288 veyron-speedy) running Gentoo Linux.

## Kernel Information

- **Kernel Version**: 6.12
- **Build Date**: Tue, 13 Jan 2026 09:20:11 +0000
- **Target Device**: ASUS Chromebook C201 (rk3288 veyron-speedy)
- **Architecture**: ARM (armv7-a)

## Package Contents

- `zImage` - Compressed kernel image (6.12)
- `rk3288-veyron-speedy.dtb` - Device tree blob for rk3288-veyron-speedy
- `kernel.config` - Kernel configuration file used for this build
- `c201-system-v6.12-20260113.img` - Full system image (4GB) with kernel and rootfs

## Installation

### Method 1: Direct Copy (Recommended)

1. Backup existing kernel on C201:
   ```bash
   cp /boot/zImage /boot/zImage.backup
   cp /boot/rk3288-veyron-speedy.dtb /boot/rk3288-veyron-speedy.dtb.backup
   ```

2. Copy new kernel files to C201:
   ```bash
   cp zImage /boot/
   cp rk3288-veyron-speedy.dtb /boot/
   ```

3. Reboot:
   ```bash
   reboot
   ```

### Method 2: Full System Image (.img) - Recommended

Write the complete system image to USB/SD card:
```bash
# WARNING: This will overwrite all data on the target device
sudo dd if=c201-system-v6.12-20260113.img of=/dev/sdX bs=4M status=progress oflag=sync
# Replace /dev/sdX with your USB/SD card device (e.g., /dev/sdb)
```

This creates a bootable system with:
- Partition 1 (64MB): Kernel partition with zImage and device tree
- Partition 2 (~4GB): Root filesystem (ext4)

Boot the C201 from USB/SD card (Ctrl+U at Developer Mode screen).

## Verification

After booting, verify the kernel version:
```bash
uname -r
cat /proc/version
```

Expected output should show kernel version 6.12.

## Checksums

SHA256 checksums for verification:

```
f63893a4a84c57f04fb1df250e8e9105c8d2a041005685e3c669d22432542e70  zImage
730640396d9678802bd707a9f0fbbd3c90d6109a0e4c8c473a4af9e0b25c0ee8  rk3288-veyron-speedy.dtb
2d8b68ec7fb3ab7b237d6bf291c76b786ae27a4c0a265202e319ccb805f0eaa0  kernel.config
da65792808dde8d7c589ead00380e41a25deb642e4bd90654f01f65749ebf972  c201-system-v6.12-20260113.img
```

## Support

For detailed build and deployment instructions, see:
- `docs/KERNEL-BUILD.md` - Build and deployment guide
- `docs/BOOT-INSTRUCTIONS.md` - Boot process documentation

## Source

This kernel was built from Linux kernel 6.12 source code.
Build environment and configuration available in the repository.
