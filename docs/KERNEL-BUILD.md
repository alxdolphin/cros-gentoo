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
- `gentoo.itb` - FIT image (kernel + DTB) for ChromeOS verified boot
- Kernel modules

Output location: `kernel/`

### 3. Package Kernel

```bash
scripts/package-kernel.sh
```

Creates `kernel-package/` with:
- `zImage` - Raw kernel image
- `rk3288-veyron-speedy.dtb` - Device tree blob
- `gentoo.itb` - FIT image (kernel + DTB)
- `vmlinux.kpart` - Signed kernel partition image (if signing succeeded)
- `kernel.flags` - Kernel boot parameters
- `kernel.config` - Kernel configuration
- `PACKAGE_INFO.txt` - Build information

**Note**: The package script attempts to sign the FIT image using ChromeOS devkeys. If signing keys are not available, the unsigned FIT image is still created and can be used for development.

## Deployment to C201

### Method 1: Signed Kernel (Recommended for ChromeOS Verified Boot)

If `vmlinux.kpart` exists (signed kernel):

1. Write signed kernel to kernel partition:
   ```bash
   sudo dd if=kernel-package/vmlinux.kpart of=/dev/sdX1 bs=4M status=progress
   # Replace /dev/sdX1 with your kernel partition device
   ```

2. Reboot the C201

### Method 2: FIT Image (Development/Testing)

If only `gentoo.itb` exists (unsigned FIT image):

1. Mount kernel partition:
   ```bash
   sudo mount /dev/sdX1 /mnt
   ```

2. Copy FIT image and kernel flags:
   ```bash
   sudo cp kernel-package/gentoo.itb /mnt/
   sudo cp kernel-package/kernel.flags /mnt/
   sudo sync
   sudo umount /mnt
   ```

3. Reboot the C201

### Method 3: Raw Files (Legacy)

For systems not using ChromeOS verified boot:

1. Mount kernel partition:
   ```bash
   sudo mount /dev/sdX1 /mnt
   ```

2. Copy raw kernel files:
   ```bash
   sudo cp kernel-package/zImage /mnt/
   sudo cp kernel-package/rk3288-veyron-speedy.dtb /mnt/
   sudo sync
   sudo umount /mnt
   ```

3. Reboot the C201

### USB/SD Card Deployment

1. Mount USB/SD card on build machine
2. Copy signed kernel (preferred):
   ```bash
   sudo dd if=kernel-package/vmlinux.kpart of=/dev/sdX1 bs=4M status=progress
   ```
   Or copy FIT image:
   ```bash
   sudo mount /dev/sdX1 /mnt
   sudo cp kernel-package/gentoo.itb /mnt/
   sudo cp kernel-package/kernel.flags /mnt/
   sudo sync
   sudo umount /mnt
   ```
3. Unmount and insert into C201

### NFS Deployment

1. Export kernel package directory via NFS
2. On C201, mount NFS share
3. Copy signed kernel or FIT image to kernel partition

### NBD Deployment

Use existing NBD setup (see `docs/NBD-SETUP.md`)

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
