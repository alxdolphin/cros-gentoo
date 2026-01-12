# Kernel Build and Deployment

Build process for C201 kernel.

## Prerequisites

- Cross-compilation toolchain installed
- Kernel source initialized via git submodule (`scripts/setup-kernel-source.sh`)
- Kernel configuration file (`.config.running` is the default)

## Build Process

### 1. Configure Kernel

Option A: Use existing config
```bash
cp .config.running linux/.config
cd linux
make olddefconfig
```

Option B: Interactive configuration
```bash
cd linux
make menuconfig
```

### 2. Build Kernel

```bash
scripts/build-kernel.sh
```

Builds:
- `zImage` - Compressed kernel image
- `rk3288-veyron-speedy.dtb` - Device tree blob
- Kernel modules

Output location: `kernel/`

### 3. Package Kernel

```bash
scripts/package-kernel.sh
```

Creates `kernel-package/` with:
- `zImage`
- `rk3288-veyron-speedy.dtb`
- `kernel.config`
- `PACKAGE_INFO.txt`

## Deployment to C201

### USB/SD Card Deployment

1. Mount USB/SD card on build machine
2. Copy files:
   ```bash
   cp kernel-package/zImage /mnt/usb/boot/
   cp kernel-package/rk3288-veyron-speedy.dtb /mnt/usb/boot/
   ```
3. Unmount and insert into C201

### NFS Deployment

1. Export kernel package directory via NFS
2. On C201, mount NFS share
3. Copy files to `/boot` on C201

### NBD Deployment

Use existing NBD setup (see `docs/NBD-SETUP.md`)

## Installation on C201

After transferring files to C201:

1. Backup existing kernel:
   ```bash
   cp /boot/zImage /boot/zImage.backup
   cp /boot/rk3288-veyron-speedy.dtb /boot/rk3288-veyron-speedy.dtb.backup
   ```

2. Install new kernel:
   ```bash
   cp zImage /boot/
   cp rk3288-veyron-speedy.dtb /boot/
   ```

3. Update bootloader if needed (ChromeOS kernel partition)

4. Reboot:
   ```bash
   reboot
   ```

## Verification

After boot, verify kernel version:
```bash
uname -r
cat /proc/version
```

Check loaded modules:
```bash
lsmod
```

## Troubleshooting

### Build fails with "No rule to make target"

Ensure kernel source submodule is initialized:
```bash
git submodule status
cd linux && make help
```

If submodule is missing:
```bash
git submodule update --init --recursive linux
```

### Cross-compiler errors

Verify CROSS_COMPILE:
```bash
echo $CROSS_COMPILE
which ${CROSS_COMPILE}gcc
```

### Device tree not found

Check DTS file exists:
```bash
ls linux/arch/arm/boot/dts/rk3288-veyron-speedy.dts
```

Build device tree separately:
```bash
cd linux
make dtbs
```

### Kernel panic on boot

1. Verify device tree matches hardware
2. Check kernel command line parameters
3. Review kernel config for required drivers
4. Boot with earlyprintk for debugging
