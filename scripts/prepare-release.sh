#!/bin/bash
# Prepare distributable release package for GitHub Releases

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_DIR="${PROJECT_ROOT}/linux"
KERNEL_PACKAGE="${PROJECT_ROOT}/kernel-package"
RELEASE_DIR="${PROJECT_ROOT}/releases"

# Get kernel version
KERNEL_VERSION=$(grep "^VERSION\|^PATCHLEVEL" "${KERNEL_DIR}/Makefile" | head -2 | sed 's/.*= *//' | tr '\n' '.' | sed 's/\.$//')
BUILD_DATE=$(date +%Y%m%d)
RELEASE_VERSION="v${KERNEL_VERSION}-${BUILD_DATE}"

echo "=== Preparing Release Package ==="
echo "Kernel Version: ${KERNEL_VERSION}"
echo "Release Version: ${RELEASE_VERSION}"
echo ""

# Check if kernel package exists
if [ ! -d "$KERNEL_PACKAGE" ]; then
    echo "Error: kernel-package directory not found"
    echo "Run: scripts/package-kernel.sh first"
    exit 1
fi

# Create releases directory
mkdir -p "$RELEASE_DIR"

# Package name
PACKAGE_NAME="c201-kernel-${RELEASE_VERSION}"
PACKAGE_DIR="${RELEASE_DIR}/${PACKAGE_NAME}"

# Create package directory
echo "Creating release package directory..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy kernel files
echo "Copying kernel files..."
cp "${KERNEL_PACKAGE}/zImage" "$PACKAGE_DIR/"
cp "${KERNEL_PACKAGE}/rk3288-veyron-speedy.dtb" "$PACKAGE_DIR/"
cp "${KERNEL_PACKAGE}/kernel.config" "$PACKAGE_DIR/"

# Create kernel image file (.img) for direct flashing
echo "Creating kernel image file..."
KERNEL_IMG="${PACKAGE_DIR}/c201-kernel-${RELEASE_VERSION}.img"
# Create a temporary directory for image contents
IMG_TMPDIR=$(mktemp -d)
mkdir -p "$IMG_TMPDIR/boot"
cp "${KERNEL_PACKAGE}/zImage" "$IMG_TMPDIR/boot/"
cp "${KERNEL_PACKAGE}/rk3288-veyron-speedy.dtb" "$IMG_TMPDIR/boot/"
# Create a simple README in the image
cat > "$IMG_TMPDIR/README.txt" <<EOF
C201 Kernel Image ${RELEASE_VERSION}
Kernel Version: ${KERNEL_VERSION}
Build Date: $(date -R)

This image contains the kernel files for ASUS Chromebook C201.
Files are located in /boot/ directory:
- zImage: Kernel image
- rk3288-veyron-speedy.dtb: Device tree blob

To use this image:
1. Write to USB/SD card: dd if=c201-kernel-${RELEASE_VERSION}.img of=/dev/sdX bs=4M status=progress
2. Or extract files: mount -o loop c201-kernel-${RELEASE_VERSION}.img /mnt
EOF

# Create ext2 filesystem image (64MB)
if command -v genext2fs &> /dev/null; then
    # Use genext2fs if available (works without loop devices)
    genext2fs -b 65536 -d "$IMG_TMPDIR" -L "C201-KERNEL" "$KERNEL_IMG" 2>/dev/null
    echo "✓ Created kernel image: $(basename "$KERNEL_IMG")"
elif command -v mke2fs &> /dev/null; then
    # Fallback: create empty image and use mke2fs with loop device
    dd if=/dev/zero of="$KERNEL_IMG" bs=1M count=64 2>/dev/null
    if LOOP_DEV=$(losetup --show -f "$KERNEL_IMG" 2>/dev/null); then
        mke2fs -q -t ext2 -L "C201-KERNEL" "$LOOP_DEV" >/dev/null 2>&1
        MNT_DIR=$(mktemp -d)
        mount "$LOOP_DEV" "$MNT_DIR" 2>/dev/null && \
        cp -r "$IMG_TMPDIR"/* "$MNT_DIR/" && \
        sync && \
        umount "$MNT_DIR" && \
        rmdir "$MNT_DIR" && \
        losetup -d "$LOOP_DEV" && \
        echo "✓ Created kernel image: $(basename "$KERNEL_IMG")"
    else
        echo "Warning: Could not create loop device, creating tar-based image instead"
        rm -f "$KERNEL_IMG"
        tar -czf "${KERNEL_IMG%.img}.tar.gz" -C "$IMG_TMPDIR" .
        KERNEL_IMG="${KERNEL_IMG%.img}.tar.gz"
    fi
else
    echo "Warning: No filesystem tools available, creating tar archive instead"
    rm -f "$KERNEL_IMG"
    tar -czf "${KERNEL_IMG%.img}.tar.gz" -C "$IMG_TMPDIR" .
    KERNEL_IMG="${KERNEL_IMG%.img}.tar.gz"
fi
rm -rf "$IMG_TMPDIR"

# Create README for the release
cat > "$PACKAGE_DIR/README.md" <<EOF
# C201 Kernel Release ${RELEASE_VERSION}

Kernel image for ASUS Chromebook C201 (rk3288 veyron-speedy) running Gentoo Linux.

## Kernel Information

- **Kernel Version**: ${KERNEL_VERSION}
- **Build Date**: $(date -R)
- **Target Device**: ASUS Chromebook C201 (rk3288 veyron-speedy)
- **Architecture**: ARM (armv7-a)

## Package Contents

- \`zImage\` - Compressed kernel image (${KERNEL_VERSION})
- \`rk3288-veyron-speedy.dtb\` - Device tree blob for rk3288-veyron-speedy
- \`kernel.config\` - Kernel configuration file used for this build
- \`c201-kernel-${RELEASE_VERSION}.img\` - Bootable kernel image file (64MB, ext2)

## Installation

### Method 1: Direct Copy (Recommended)

1. Backup existing kernel on C201:
   \`\`\`bash
   cp /boot/zImage /boot/zImage.backup
   cp /boot/rk3288-veyron-speedy.dtb /boot/rk3288-veyron-speedy.dtb.backup
   \`\`\`

2. Copy new kernel files to C201:
   \`\`\`bash
   cp zImage /boot/
   cp rk3288-veyron-speedy.dtb /boot/
   \`\`\`

3. Reboot:
   \`\`\`bash
   reboot
   \`\`\`

### Method 2: Kernel Image File (.img)

Write the kernel image directly to USB/SD card:
\`\`\`bash
# WARNING: This will overwrite data on the target device
sudo dd if=c201-kernel-${RELEASE_VERSION}.img of=/dev/sdX bs=4M status=progress oflag=sync
# Replace /dev/sdX with your USB/SD card device (e.g., /dev/sdb)
\`\`\`

### Method 3: Extract from Image

Mount the image and extract files:
\`\`\`bash
# Mount the image
sudo mkdir -p /mnt/kernel-img
sudo mount -o loop c201-kernel-${RELEASE_VERSION}.img /mnt/kernel-img

# Copy files
cp /mnt/kernel-img/boot/zImage /boot/
cp /mnt/kernel-img/boot/rk3288-veyron-speedy.dtb /boot/

# Unmount
sudo umount /mnt/kernel-img
\`\`\`

## Verification

After booting, verify the kernel version:
\`\`\`bash
uname -r
cat /proc/version
\`\`\`

Expected output should show kernel version ${KERNEL_VERSION}.

## Checksums

SHA256 checksums for verification:

\`\`\`
$(cd "$PACKAGE_DIR" && sha256sum zImage rk3288-veyron-speedy.dtb kernel.config c201-kernel-${RELEASE_VERSION}.img 2>/dev/null | sed 's|'"$PACKAGE_DIR"'/||')
\`\`\`

## Support

For detailed build and deployment instructions, see:
- \`docs/KERNEL-BUILD.md\` - Build and deployment guide
- \`docs/BOOT-INSTRUCTIONS.md\` - Boot process documentation

## Source

This kernel was built from Linux kernel ${KERNEL_VERSION} source code.
Build environment and configuration available in the repository.
EOF

# Create release notes
cat > "$RELEASE_DIR/RELEASE_NOTES-${RELEASE_VERSION}.md" <<EOF
# Release Notes - ${RELEASE_VERSION}

## C201 Kernel for Gentoo Linux

**Release Date**: $(date -R)  
**Kernel Version**: ${KERNEL_VERSION}  
**Target Device**: ASUS Chromebook C201 (rk3288 veyron-speedy)

## What's Included

This release contains a pre-built Linux kernel for the ASUS Chromebook C201 running Gentoo Linux.

### Files

- \`zImage\` - Kernel image (${KERNEL_VERSION})
- \`rk3288-veyron-speedy.dtb\` - Device tree blob
- \`kernel.config\` - Kernel configuration
- \`c201-kernel-${RELEASE_VERSION}.img\` - Bootable kernel image (64MB)

## Features

- Linux kernel ${KERNEL_VERSION}
- Optimized for rk3288-veyron-speedy (ASUS Chromebook C201)
- NETFILTER support (iptables, nftables)
- BTRFS filesystem support
- CRYPTO libraries support
- All required drivers for C201 hardware

## Installation

See \`README.md\` in the package for installation instructions.

## Verification

After installation, verify the kernel:
\`\`\`bash
uname -r
\`\`\`

Should display: \`${KERNEL_VERSION}\`

## Build Information

- **Cross Compiler**: arm-linux-gnueabihf-gcc
- **Build Host**: $(hostname)
- **Build Date**: $(date -R)

## Source Code

The kernel source and build configuration are available in this repository.
To build from source, follow the instructions in \`README.md\`.

## Previous Releases

See GitHub Releases for previous versions.
EOF

# Create archive
echo "Creating archive..."
cd "$RELEASE_DIR"
tar -czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}/"

# Create zip archive (for Windows users)
echo "Creating ZIP archive..."
zip -r "${PACKAGE_NAME}.zip" "${PACKAGE_NAME}/" > /dev/null

# Copy .img file to release directory for direct download
echo "Copying kernel image file..."
if [ -f "${PACKAGE_DIR}/c201-kernel-${RELEASE_VERSION}.img" ]; then
    cp "${PACKAGE_DIR}/c201-kernel-${RELEASE_VERSION}.img" "${RELEASE_DIR}/"
elif [ -f "${PACKAGE_DIR}/c201-kernel-${RELEASE_VERSION}.tar.gz" ]; then
    cp "${PACKAGE_DIR}/c201-kernel-${RELEASE_VERSION}.tar.gz" "${RELEASE_DIR}/"
fi

# Generate checksums
echo "Generating checksums..."
cat > "${PACKAGE_NAME}.sha256" <<EOF
# SHA256 Checksums for ${PACKAGE_NAME}
# Generated: $(date -R)

$(cd "$RELEASE_DIR" && sha256sum "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}.zip" c201-kernel-${RELEASE_VERSION}.img 2>/dev/null || sha256sum "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}.zip")
EOF

# Display summary
echo ""
echo "=== Release Package Ready ==="
echo ""
echo "Package Name: ${PACKAGE_NAME}"
echo "Location: ${RELEASE_DIR}/"
echo ""
echo "Files created:"
ls -lh "${RELEASE_DIR}/${PACKAGE_NAME}"*
echo ""
echo "Package contents:"
ls -lh "${PACKAGE_DIR}/"
echo ""
echo "To publish this release:"
echo "1. Go to GitHub Releases"
echo "2. Create a new release with tag: ${RELEASE_VERSION}"
echo "3. Upload: ${PACKAGE_NAME}.tar.gz"
echo "4. Upload: ${PACKAGE_NAME}.zip (optional)"
echo "5. Upload: c201-kernel-${RELEASE_VERSION}.img (kernel image)"
echo "6. Upload: ${PACKAGE_NAME}.sha256"
echo "7. Upload: RELEASE_NOTES-${RELEASE_VERSION}.md as release notes"
echo ""
echo "Or use GitHub CLI:"
echo "  gh release create ${RELEASE_VERSION} \\"
echo "    --title \"C201 Kernel ${RELEASE_VERSION}\" \\"
echo "    --notes-file releases/RELEASE_NOTES-${RELEASE_VERSION}.md \\"
echo "    releases/${PACKAGE_NAME}.tar.gz \\"
echo "    releases/c201-kernel-${RELEASE_VERSION}.img \\"
echo "    releases/${PACKAGE_NAME}.sha256"
echo ""
