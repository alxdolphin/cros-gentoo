# C201 Gentoo Recovery Image

## Image Files

Recovery images are available in GitHub Releases.

| File | Size | Purpose |
|------|------|---------|
| `c201-preconfigured.img` | 4GB | Recovery image with pre-configured Gentoo system |

## Pre-Configured Settings

### Pre-Installed Components
- Portage tree (synced Jan 2026)
- Wi-Fi firmware (brcmfmac4354-sdio.bin + clm_blob + nvram)
- iwd (Wi-Fi daemon)
- micro text editor
- bash-completion
- Network configuration (DHCP for wired/wireless)
- Essential services enabled (iwd, sshd, networkd, timesyncd)
- First-boot setup script

### System Configuration
- Hostname: `c201-gentoo`
- Timezone: `America/New_York`
- Locale: `en_US.UTF-8`
- Root Password: `gentoo` (change after first login)

### Compiler Optimization (make.conf)
Optimized for RK3288 SoC (Cortex-A17):
```
COMMON_FLAGS="-O2 -pipe -march=armv7-a -mtune=cortex-a17 -mfpu=neon -mfloat-abi=hard"
MAKEOPTS="-j3"
```

### Enabled Services
- `systemd-networkd` - Network management
- `systemd-resolved` - DNS resolution
- `sshd` - SSH server
- `first-boot-setup` - First boot initialization

### Network Configuration
- Wired (eth*, en*): DHCP enabled
- Wireless (wlan*, wl*): DHCP enabled

### First Boot Service
On first boot, the system will:
1. Generate SSH host keys
2. Configure DNS resolver symlink
3. Mark first boot as complete

## Downloading and Writing to SD Card / USB

1. Download the recovery image from GitHub Releases

2. Identify the target device:
   ```bash
   lsblk
   ```

3. Write the image (WARNING: this operation destroys existing data on the target device):
   ```bash
   sudo dd if=c201-preconfigured.img of=/dev/sdX bs=4M status=progress oflag=sync
   # Replace /dev/sdX with your actual device (e.g., /dev/sdb)
   ```

## Booting on C201

1. Insert the SD card / USB drive
2. Power on the C201
3. At the Developer Mode warning, press Ctrl+U to boot from USB/SD
4. Login as root with password `gentoo`
5. Change the root password immediately: `passwd`

## Post-Boot Tasks

### Sync Portage (first time)
```bash
emerge-webrsync
# or
emerge --sync
```

### Wi-Fi Firmware
The Wi-Fi firmware is pre-installed:
- `/lib/firmware/brcm/brcmfmac4354-sdio.bin` - Cypress firmware binary (601KB)
- `/lib/firmware/brcm/brcmfmac4354-sdio.clm_blob` - CLM data
- `/lib/firmware/brcm/brcmfmac4354-sdio.txt` - NVRAM configuration

### Wi-Fi NVRAM File
The Wi-Fi NVRAM file is pre-installed at:
```
/lib/firmware/brcm/brcmfmac4354-sdio.txt
```

Source: [ChromiumOS overlay-veyron](https://chromium.googlesource.com/chromiumos/overlays/board-overlays/+/master/overlay-veyron/chromeos-base/chromeos-bsp-veyron/files/firmware/brcmfmac4354-sdio.txt)

### Connect to Wi-Fi (using iwd)
iwd is pre-installed and enabled. Connect using `iwctl`:

```bash
# Interactive mode
iwctl

# Inside iwctl:
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "YOUR_WIFI_SSID"
# Enter password when prompted
[iwd]# exit

# Or one-liner:
iwctl station wlan0 connect "YOUR_WIFI_SSID"
```

Networks are saved automatically to `/var/lib/iwd/`.

## Recovery

If the system becomes unusable:
1. Download the latest recovery image from GitHub Releases
2. Write the image to a new SD card/USB drive
3. Boot from the recovery image

## Chroot Access

For further customization, mount the recovery image manually:

```bash
# Create mount point
mkdir -p /mnt/c201-chroot

# Attach loop device
losetup -fP c201-preconfigured.img
LOOP=$(losetup -j c201-preconfigured.img | cut -d: -f1)

# Mount root partition (partition 2)
mount ${LOOP}p2 /mnt/c201-chroot

# Setup bind mounts
mount --bind /proc /mnt/c201-chroot/proc
mount --bind /sys /mnt/c201-chroot/sys
mount --bind /dev /mnt/c201-chroot/dev
mount --bind /dev/pts /mnt/c201-chroot/dev/pts

# Enter chroot
chroot /mnt/c201-chroot /bin/bash

# After exiting chroot, unmount:
umount /mnt/c201-chroot/dev/pts
umount /mnt/c201-chroot/dev
umount /mnt/c201-chroot/sys
umount /mnt/c201-chroot/proc
umount /mnt/c201-chroot
losetup -d $LOOP
```

## Partition Layout

| Partition | Type | Size | Content |
|-----------|------|------|---------|
| 1 | ChromeOS Kernel | 64MB | Signed kernel (vmlinux.kpart) |
| 2 | Linux | ~3.9GB | Root filesystem (ext4) |

Root PARTUUID: `7999E767-A69E-49BF-8C9C-6E2B0B6F4E93`
