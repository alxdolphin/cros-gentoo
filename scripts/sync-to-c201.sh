#!/bin/bash
# Helper script for syncing kernel artifacts to C201
# Provides instructions for different transfer methods

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="${PROJECT_ROOT}/kernel-package"

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "Error: kernel-package/ not found"
    echo "Run: scripts/package-kernel.sh first"
    exit 1
fi

echo "=== C201 Kernel Transfer Methods ==="
echo ""

echo "Method 1: USB/SD Card"
echo "  1. Mount USB/SD card"
echo "  2. Copy files:"
echo "     cp ${PACKAGE_DIR}/zImage /mnt/usb/boot/"
echo "     cp ${PACKAGE_DIR}/rk3288-veyron-speedy.dtb /mnt/usb/boot/"
echo "  3. Unmount and insert into C201"
echo ""

echo "Method 2: NFS"
echo "  1. Export package directory:"
echo "     echo '${PACKAGE_DIR} *(ro)' >> /etc/exports"
echo "     exportfs -ra"
echo "  2. On C201:"
echo "     mount -t nfs <server-ip>:${PACKAGE_DIR} /mnt/nfs"
echo "     cp /mnt/nfs/zImage /boot/"
echo "     cp /mnt/nfs/rk3288-veyron-speedy.dtb /boot/"
echo ""

echo "Method 3: SCP (if C201 has SSH)"
echo "  scp ${PACKAGE_DIR}/zImage root@<c201-ip>:/boot/"
echo "  scp ${PACKAGE_DIR}/rk3288-veyron-speedy.dtb root@<c201-ip>:/boot/"
echo ""

echo "Package location: ${PACKAGE_DIR}"
echo "Files:"
ls -lh "$PACKAGE_DIR" | grep -E "(zImage|dtb|config)"
