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

# Copy FIT image if available
if [ -f "${KERNEL_PACKAGE}/gentoo.itb" ]; then
    echo "Copying FIT image..."
    cp "${KERNEL_PACKAGE}/gentoo.itb" "$PACKAGE_DIR/"
fi

# Copy signed kernel if available
if [ -f "${KERNEL_PACKAGE}/vmlinux.kpart" ]; then
    echo "Copying signed kernel partition..."
    cp "${KERNEL_PACKAGE}/vmlinux.kpart" "$PACKAGE_DIR/"
fi

# Copy kernel flags if available
if [ -f "${KERNEL_PACKAGE}/kernel.flags" ]; then
    echo "Copying kernel flags..."
    cp "${KERNEL_PACKAGE}/kernel.flags" "$PACKAGE_DIR/"
fi

# Create full system image (.img) with kernel and rootfs
echo "Creating full system image (kernel + rootfs)..."
if [ -f "${SCRIPT_DIR}/create-system-image.sh" ]; then
    "${SCRIPT_DIR}/create-system-image.sh"
    SYSTEM_IMG="${PROJECT_ROOT}/releases/c201-system-${RELEASE_VERSION}.img"
    if [ -f "$SYSTEM_IMG" ]; then
        cp "$SYSTEM_IMG" "${PACKAGE_DIR}/"
        echo "✓ Created full system image: c201-system-${RELEASE_VERSION}.img"
    else
        echo "Warning: System image creation failed"
        SYSTEM_IMG=""
    fi
else
    echo "Warning: create-system-image.sh not found, skipping system image creation"
    SYSTEM_IMG=""
fi

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
- \`gentoo.itb\` - FIT image (kernel + DTB) for ChromeOS verified boot
- \`vmlinux.kpart\` - Signed kernel partition image (if signing succeeded)
- \`kernel.flags\` - Kernel boot parameters
- \`kernel.config\` - Kernel configuration file used for this build
- \`c201-system-${RELEASE_VERSION}.img.gz\` - Compressed full system image (4GB) with kernel and rootfs

## Installation

### Method 1: Signed Kernel (Recommended for ChromeOS Verified Boot)

If \`vmlinux.kpart\` exists:

1. Write signed kernel to kernel partition:
   \`\`\`bash
   sudo dd if=vmlinux.kpart of=/dev/sdX1 bs=4M status=progress
   # Replace /dev/sdX1 with your kernel partition device
   \`\`\`

2. Reboot the C201

### Method 2: FIT Image (Development/Testing)

If only \`gentoo.itb\` exists:

1. Mount kernel partition:
   \`\`\`bash
   sudo mount /dev/sdX1 /mnt
   \`\`\`

2. Copy FIT image and kernel flags:
   \`\`\`bash
   sudo cp gentoo.itb /mnt/
   sudo cp kernel.flags /mnt/
   sudo sync
   sudo umount /mnt
   \`\`\`

3. Reboot the C201

### Method 3: Raw Files (Legacy)

For systems not using ChromeOS verified boot:

1. Mount kernel partition:
   \`\`\`bash
   sudo mount /dev/sdX1 /mnt
   \`\`\`

2. Copy raw kernel files:
   \`\`\`bash
   sudo cp zImage /mnt/
   sudo cp rk3288-veyron-speedy.dtb /mnt/
   sudo sync
   sudo umount /mnt
   \`\`\`

3. Reboot the C201

### Method 2: Full System Image (.img) - Recommended

Write the complete system image to USB/SD card:
\`\`\`bash
# WARNING: This will overwrite all data on the target device
sudo dd if=c201-system-${RELEASE_VERSION}.img of=/dev/sdX bs=4M status=progress oflag=sync
# Replace /dev/sdX with your USB/SD card device (e.g., /dev/sdb)
\`\`\`

This creates a bootable system with:
- Partition 1 (64MB): Kernel partition with zImage and device tree
- Partition 2 (~4GB): Root filesystem (ext4)

Boot the C201 from USB/SD card (Ctrl+U at Developer Mode screen).

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
$(cd "$PACKAGE_DIR" && sha256sum zImage rk3288-veyron-speedy.dtb kernel.config c201-system-${RELEASE_VERSION}.img 2>/dev/null | sed 's|'"$PACKAGE_DIR"'/||' || sha256sum zImage rk3288-veyron-speedy.dtb kernel.config 2>/dev/null | sed 's|'"$PACKAGE_DIR"'/||')
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
- \`gentoo.itb\` - FIT image (kernel + DTB) for ChromeOS verified boot
- \`vmlinux.kpart\` - Signed kernel partition image (if signing succeeded)
- \`kernel.flags\` - Kernel boot parameters
- \`kernel.config\` - Kernel configuration
- \`c201-system-${RELEASE_VERSION}.img.gz\` - Compressed full system image (~16MB, decompresses to ~4.1GB)

## Features

- Linux kernel ${KERNEL_VERSION}
- Optimized for rk3288-veyron-speedy (ASUS Chromebook C201)
- NETFILTER support (iptables, nftables)
- BTRFS filesystem support
- CRYPTO libraries support
- All required drivers for C201 hardware

## Installation

### Full System Image (Recommended)
1. Download \`c201-system-${RELEASE_VERSION}.img.gz\`
2. Decompress: \`gunzip c201-system-${RELEASE_VERSION}.img.gz\`
3. Write to USB/SD card: \`sudo dd if=c201-system-${RELEASE_VERSION}.img of=/dev/sdX bs=4M status=progress oflag=sync\`

### Individual Kernel Files
See \`README.md\` in the package for detailed installation instructions using:
- Signed kernel (\`vmlinux.kpart\`) - Recommended for ChromeOS verified boot
- FIT image (\`gentoo.itb\`) - For development/testing
- Raw files (\`zImage\` + \`rk3288-veyron-speedy.dtb\`) - Legacy method

## Verification

After installation, verify the kernel:
\`\`\`bash
uname -r
\`\`\`

Should display: \`${KERNEL_VERSION}\`

## Build Information

- **Cross Compiler**: armv7a-unknown-linux-gnueabihf-gcc
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

# Copy and compress system image file to release directory
echo "Copying and compressing system image file..."
SYSTEM_IMG_SOURCE="${PROJECT_ROOT}/releases/c201-system-${RELEASE_VERSION}.img"
if [ -f "$SYSTEM_IMG_SOURCE" ]; then
    # Compress the image (GitHub has 2GB limit per file)
    echo "Compressing system image for GitHub release..."
    if [ ! -f "${SYSTEM_IMG_SOURCE}.gz" ]; then
        gzip -9 "$SYSTEM_IMG_SOURCE"
    fi
    SYSTEM_IMG_FILE="c201-system-${RELEASE_VERSION}.img.gz"
    if [ -f "${SYSTEM_IMG_SOURCE}.gz" ] && [ ! -f "${RELEASE_DIR}/${SYSTEM_IMG_FILE}" ]; then
        cp "${SYSTEM_IMG_SOURCE}.gz" "${RELEASE_DIR}/"
    fi
    echo "✓ Compressed system image: ${SYSTEM_IMG_FILE}"
else
    echo "Warning: System image not found"
    SYSTEM_IMG_FILE=""
fi

# Generate checksums
echo "Generating checksums..."
cat > "${PACKAGE_NAME}.sha256" <<EOF
# SHA256 Checksums for ${PACKAGE_NAME}
# Generated: $(date -R)

$(cd "$RELEASE_DIR" && sha256sum "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}.zip" ${SYSTEM_IMG_FILE:+"$SYSTEM_IMG_FILE"} 2>/dev/null | head -3 || sha256sum "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}.zip")
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
echo "5. Upload: c201-system-${RELEASE_VERSION}.img.gz (compressed full system image)"
echo "6. Upload: ${PACKAGE_NAME}.sha256"
echo "7. Upload: RELEASE_NOTES-${RELEASE_VERSION}.md as release notes"
echo ""
echo "Or use GitHub CLI:"
echo "  gh release create ${RELEASE_VERSION} \\"
echo "    --title \"C201 Kernel ${RELEASE_VERSION}\" \\"
echo "    --notes-file releases/RELEASE_NOTES-${RELEASE_VERSION}.md \\"
echo "    releases/${PACKAGE_NAME}.tar.gz \\"
echo "    releases/c201-system-${RELEASE_VERSION}.img.gz \\"
echo "    releases/${PACKAGE_NAME}.sha256"
echo ""
