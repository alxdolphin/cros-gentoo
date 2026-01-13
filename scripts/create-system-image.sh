#!/bin/bash
# Create full C201 system image with kernel and rootfs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_PACKAGE="${PROJECT_ROOT}/kernel-package"
KERNEL_DIR="${PROJECT_ROOT}/linux"

# Configuration
KERNEL_VERSION=$(grep "^VERSION\|^PATCHLEVEL" "${KERNEL_DIR}/Makefile" | head -2 | sed 's/.*= *//' | tr '\n' '.' | sed 's/\.$//')
BUILD_DATE=$(date +%Y%m%d)
RELEASE_VERSION="v${KERNEL_VERSION}-${BUILD_DATE}"

# Partition sizes
KERNEL_PART_SIZE=64M      # Partition 1: Kernel partition
ROOTFS_PART_SIZE=4G       # Partition 2: Root filesystem
IMAGE_SIZE=4096M          # Total image size (4GB)

# ChromeOS kernel partition type GUID
CHROMEOS_KERNEL_TYPE="FE3A2A5D-4F32-41A7-B725-ACCC3285A309"

# Root PARTUUID - read from kernel.flags if available, otherwise use default
KERNEL_FLAGS="${PROJECT_ROOT}/kernel/kernel.flags"
if [ -f "$KERNEL_FLAGS" ] && grep -q "root=PARTUUID=" "$KERNEL_FLAGS"; then
    # Extract PARTUUID from kernel.flags (format: root=PARTUUID=xxxx-xxxx-...)
    ROOT_PARTUUID=$(grep -o "root=PARTUUID=[a-fA-F0-9-]*" "$KERNEL_FLAGS" | cut -d= -f3 | tr '[:lower:]' '[:upper:]')
    echo "Using PARTUUID from kernel.flags: ${ROOT_PARTUUID}"
else
    # Default PARTUUID (from docs)
    ROOT_PARTUUID="7999E767-A69E-49BF-8C9C-6E2B0B6F4E93"
    echo "Using default PARTUUID: ${ROOT_PARTUUID}"
fi

echo "=== Creating C201 Full System Image ==="
echo "Kernel Version: ${KERNEL_VERSION}"
echo "Release Version: ${RELEASE_VERSION}"
echo ""

# Check prerequisites
if [ ! -d "$KERNEL_PACKAGE" ]; then
    echo "Error: kernel-package directory not found"
    echo "Run: scripts/package-kernel.sh first"
    exit 1
fi

if [ ! -f "${KERNEL_PACKAGE}/zImage" ]; then
    echo "Error: zImage not found in kernel-package"
    exit 1
fi

# Check for required tools - use parted or gdisk
PARTED_CMD=$(command -v parted || echo "")
GDISK_CMD=$(command -v gdisk || command -v sgdisk || echo "")

if [ -z "$PARTED_CMD" ] && [ -z "$GDISK_CMD" ]; then
    echo "Installing required tools..."
    sudo apt-get update -qq && sudo apt-get install -y -qq gdisk e2fsprogs parted >/dev/null 2>&1
    PARTED_CMD=$(command -v parted || echo "")
    GDISK_CMD=$(command -v gdisk || command -v sgdisk || echo "")
fi

if [ -z "$PARTED_CMD" ] && [ -z "$GDISK_CMD" ]; then
    echo "Error: No partition tool found (parted/gdisk). Please install gdisk or parted."
    exit 1
fi

# Create image file
IMAGE_FILE="${PROJECT_ROOT}/releases/c201-system-${RELEASE_VERSION}.img"
echo "Creating system image: $(basename "$IMAGE_FILE")"
rm -f "$IMAGE_FILE"
dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=4096 2>/dev/null

# Create partition table (GPT) with ChromeOS-compatible partitions
echo "Creating partition table..."
if [ -n "$GDISK_CMD" ]; then
    # Use sgdisk for ChromeOS partitions (non-interactive)
    # Create GPT table
    sgdisk --clear "$IMAGE_FILE" >/dev/null 2>&1
    
    # Partition 1: ChromeOS kernel partition (64MB)
    # Type: FE3A2A5D-4F32-41A7-B725-ACCC3285A309 (ChromeOS kernel)
    sgdisk --new=1:2048:+64M --change-name=1:"kernel" --typecode=1:${CHROMEOS_KERNEL_TYPE} "$IMAGE_FILE" >/dev/null 2>&1
    
    # Partition 2: Root filesystem (~4GB)
    # Type: 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem)
    sgdisk --new=2:133120 --change-name=2:"root" --typecode=2:8300 "$IMAGE_FILE" >/dev/null 2>&1
    
    # Set root partition UUID if specified
    if [ -n "$ROOT_PARTUUID" ]; then
        sgdisk --partition-guid=2:${ROOT_PARTUUID} "$IMAGE_FILE" >/dev/null 2>&1
    fi
    
    # Set ChromeOS kernel attributes using cgpt if available
    if command -v cgpt &> /dev/null; then
        cgpt add -i 1 -P 10 -T 5 -S 1 "$IMAGE_FILE" 2>/dev/null || true
    else
        # Fallback: Set legacy_boot flag (basic ChromeOS compatibility)
        sgdisk --attributes=1:set:48 "$IMAGE_FILE" >/dev/null 2>&1
    fi
    
    # Repair GPT backup header (needed after direct file manipulation)
    sgdisk --verify "$IMAGE_FILE" >/dev/null 2>&1 || true
    
    echo "✓ Partition table created with ChromeOS-compatible partitions"
else
    # Fallback: Use parted (less precise for ChromeOS)
    PARTED_SECTOR_SIZE=512
    $PARTED_CMD -s "$IMAGE_FILE" mklabel gpt 2>/dev/null
    $PARTED_CMD -s "$IMAGE_FILE" unit s mkpart "kernel" 2048 133119 2>/dev/null
    $PARTED_CMD -s "$IMAGE_FILE" unit s mkpart "root" 133120 100% 2>/dev/null
    $PARTED_CMD -s "$IMAGE_FILE" set 1 legacy_boot on 2>/dev/null
    
    # Set root PARTUUID using sgdisk if available
    if command -v sgdisk &> /dev/null && [ -n "$ROOT_PARTUUID" ]; then
        echo "Setting root PARTUUID using sgdisk..."
        sgdisk --partition-guid=2:${ROOT_PARTUUID} "$IMAGE_FILE" 2>/dev/null || true
    fi
fi

# Use direct file method (works without loop devices)
echo "Creating partitions using direct file method..."
USE_LOOP=false

# Check if loop devices are actually available
if [ -e /dev/loop0 ] && timeout 1 sudo losetup --show -f "$IMAGE_FILE" >/dev/null 2>&1; then
    USE_LOOP=true
    LOOP_DEV=$(sudo losetup --show -f -P "$IMAGE_FILE" 2>/dev/null)
fi

if [ "$USE_LOOP" = "false" ] || [ -z "$LOOP_DEV" ]; then
    echo "Loop device not available, using direct file method..."
    USE_LOOP=false
    
    # Create kernel partition image directly using genext2fs
    KERNEL_PART_IMG=$(mktemp)
    KERNEL_TMPDIR=$(mktemp -d)
    cp "${KERNEL_PACKAGE}/zImage" "$KERNEL_TMPDIR/"
    cp "${KERNEL_PACKAGE}/rk3288-veyron-speedy.dtb" "$KERNEL_TMPDIR/" 2>/dev/null || true
    
    if command -v genext2fs &> /dev/null; then
        genext2fs -b 65536 -d "$KERNEL_TMPDIR" -L "kernel" "$KERNEL_PART_IMG" 2>/dev/null
        # Write kernel partition to offset (2048 sectors * 512 = 1048576 bytes)
        dd if="$KERNEL_PART_IMG" of="$IMAGE_FILE" bs=512 seek=2048 conv=notrunc 2>/dev/null
        rm -f "$KERNEL_PART_IMG"
        rm -rf "$KERNEL_TMPDIR"
        echo "✓ Kernel partition created (direct method)"
    else
        echo "Error: genext2fs required for loop-device-free method"
        rm -rf "$KERNEL_TMPDIR"
        exit 1
    fi
    
    # Create rootfs partition image
    ROOTFS_PART_IMG=$(mktemp)
    ROOTFS_TMPDIR=$(mktemp -d)
    
    ROOTFS_SOURCE="${PROJECT_ROOT}/rootfs"
    if [ -d "$ROOTFS_SOURCE" ]; then
        cp -a "$ROOTFS_SOURCE"/* "$ROOTFS_TMPDIR/" 2>/dev/null || true
    else
        mkdir -p "$ROOTFS_TMPDIR"/{bin,boot,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
    fi
    
    # Create ext4 filesystem image (using genext2fs which supports ext4)
    genext2fs -b 4194304 -d "$ROOTFS_TMPDIR" -L "root" "$ROOTFS_PART_IMG" 2>/dev/null
    # Write rootfs partition to offset (133120 sectors * 512 = 68157440 bytes)
    dd if="$ROOTFS_PART_IMG" of="$IMAGE_FILE" bs=512 seek=133120 conv=notrunc 2>/dev/null
    rm -f "$ROOTFS_PART_IMG"
    rm -rf "$ROOTFS_TMPDIR"
    echo "✓ Root filesystem partition created (direct method)"
    
else
    USE_LOOP=true
    # Wait for partitions to be available
    sleep 1
    sudo partprobe "$LOOP_DEV" 2>/dev/null || true
    sleep 1

    # Format kernel partition (ext2, 64MB)
    echo "Formatting kernel partition..."
    sudo mkfs.ext2 -q -L "kernel" "${LOOP_DEV}p1" 2>/dev/null || {
        echo "Warning: mkfs.ext2 failed, trying alternative method"
        sudo mke2fs -t ext2 -q -L "kernel" "${LOOP_DEV}p1" 2>/dev/null
    }

    # Mount kernel partition and copy kernel files
    KERNEL_MNT=$(mktemp -d)
    sudo mount "${LOOP_DEV}p1" "$KERNEL_MNT"
    sudo cp "${KERNEL_PACKAGE}/zImage" "$KERNEL_MNT/"
    sudo cp "${KERNEL_PACKAGE}/rk3288-veyron-speedy.dtb" "$KERNEL_MNT/" 2>/dev/null || true
    sudo sync
    sudo umount "$KERNEL_MNT"
    rmdir "$KERNEL_MNT"
    echo "✓ Kernel partition created"

    # Format root filesystem partition (ext4)
    echo "Formatting root filesystem partition..."
    sudo mkfs.ext4 -q -L "root" -F "${LOOP_DEV}p2" 2>/dev/null || {
        echo "Warning: mkfs.ext4 failed, trying alternative method"
        sudo mke2fs -t ext4 -q -L "root" -F "${LOOP_DEV}p2" 2>/dev/null
    }

    # Mount root partition
    ROOTFS_MNT=$(mktemp -d)
    sudo mount "${LOOP_DEV}p2" "$ROOTFS_MNT"

# Check if we have a rootfs source
ROOTFS_SOURCE="${PROJECT_ROOT}/rootfs"
if [ -d "$ROOTFS_SOURCE" ]; then
    echo "Found existing rootfs at $ROOTFS_SOURCE"
    echo "Copying rootfs..."
    sudo cp -a "$ROOTFS_SOURCE"/* "$ROOTFS_MNT/" 2>/dev/null || {
        echo "Warning: Some files may not have copied correctly"
    }
else
    echo "No rootfs found. Creating minimal rootfs structure..."
    echo "Note: You'll need to populate this with Gentoo stage3 or existing rootfs"
    
    # Create minimal directory structure
    sudo mkdir -p "$ROOTFS_MNT"/{bin,boot,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
    sudo mkdir -p "$ROOTFS_MNT"/usr/{bin,lib,sbin,share}
    sudo mkdir -p "$ROOTFS_MNT"/var/{log,lib,run}
    
    # Create a README
    sudo bash -c "cat > \"$ROOTFS_MNT/README.txt\"" <<EOF
C201 System Image ${RELEASE_VERSION}
Kernel Version: ${KERNEL_VERSION}
Build Date: $(date -R)

This is a minimal rootfs structure. To complete the system image:

1. Download Gentoo ARMv7 systemd stage3 tarball:
   wget https://distfiles.gentoo.org/releases/arm/autobuilds/latest-stage3-armv7a-systemd.txt

2. Extract stage3 into this partition:
   tar xpf stage3-*.tar.xz -C /mnt/rootfs

3. Configure the system (fstab, hostname, etc.)

Alternatively, if you have an existing C201 rootfs, copy it to:
${PROJECT_ROOT}/rootfs/

Then re-run this script.
EOF
fi

# Copy kernel modules if they exist
if [ -d "${PROJECT_ROOT}/linux/lib/modules" ]; then
    echo "Copying kernel modules..."
    sudo mkdir -p "$ROOTFS_MNT/lib/modules"
    sudo cp -r "${PROJECT_ROOT}/linux/lib/modules"/* "$ROOTFS_MNT/lib/modules/" 2>/dev/null || true
fi

# Create /boot directory and symlink kernel
sudo mkdir -p "$ROOTFS_MNT/boot"
sudo ln -sf /../zImage "$ROOTFS_MNT/boot/zImage" 2>/dev/null || true

# Set root password (if chroot tools available)
if command -v chroot &> /dev/null; then
    echo "Setting up basic system files..."
    # Create minimal /etc/passwd
    sudo bash -c "cat > \"$ROOTFS_MNT/etc/passwd\"" <<EOF
root:x:0:0:root:/root:/bin/bash
EOF
    
    # Create minimal /etc/group
    sudo bash -c "cat > \"$ROOTFS_MNT/etc/group\"" <<EOF
root:x:0:
EOF
fi

    sudo sync
    sudo umount "$ROOTFS_MNT"
    rmdir "$ROOTFS_MNT"

    # Cleanup loop device
    sudo losetup -d "$LOOP_DEV"
fi

echo ""
echo "=== System Image Created ==="
echo "Image: $IMAGE_FILE"
echo "Size: $(du -h "$IMAGE_FILE" | cut -f1)"
echo ""
echo "Partition layout:"
echo "  Partition 1 (64MB): Kernel partition (ext2)"
echo "  Partition 2 (~4GB): Root filesystem (ext4)"
echo ""
echo "To use this image:"
echo "  sudo dd if=\"$IMAGE_FILE\" of=/dev/sdX bs=4M status=progress oflag=sync"
echo ""
