#!/bin/bash
# Package kernel artifacts for C201 deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_DIR="${PROJECT_ROOT}/linux"
KERNEL_OUTPUT="${PROJECT_ROOT}/kernel"
PACKAGE_DIR="${PROJECT_ROOT}/kernel-package"

# Device tree source
DTB_SOURCE="${KERNEL_DIR}/arch/arm/boot/dts/rk3288-veyron-speedy.dtb"

echo "=== Packaging kernel for C201 ==="

# Check for required files
if [ ! -f "${KERNEL_OUTPUT}/zImage" ]; then
    echo "Error: zImage not found. Build kernel first: scripts/build-kernel.sh"
    exit 1
fi

# Create package directory
mkdir -p "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Copy kernel image
echo "Copying kernel image..."
cp "${KERNEL_OUTPUT}/zImage" .

# Copy device tree
if [ -f "${KERNEL_OUTPUT}/rk3288-veyron-speedy.dtb" ]; then
    echo "Copying device tree..."
    cp "${KERNEL_OUTPUT}/rk3288-veyron-speedy.dtb" .
else
    echo "Warning: Device tree not found"
fi

# Copy kernel config
if [ -f "${KERNEL_OUTPUT}/config-latest" ]; then
    echo "Copying kernel config..."
    cp "${KERNEL_OUTPUT}/config-latest" kernel.config
fi

# Create info file
cat > PACKAGE_INFO.txt <<EOF
C201 Kernel Package
Generated: $(date)
Kernel Version: $(grep "^VERSION\|^PATCHLEVEL" "${KERNEL_DIR}/Makefile" | head -2 | sed 's/.*= *//' | tr '\n' '.' | sed 's/\.$//')
Build Host: $(hostname)
Cross Compiler: ${CROSS_COMPILE:-arm-linux-gnueabihf-}

Files:
- zImage: Kernel image for rk3288-veyron-speedy
- rk3288-veyron-speedy.dtb: Device tree blob
- kernel.config: Kernel configuration used

To deploy:
1. Copy zImage and rk3288-veyron-speedy.dtb to C201
2. Follow instructions in docs/KERNEL-BUILD.md
EOF

echo "✓ Package created in: $PACKAGE_DIR"
echo ""
echo "Package contents:"
ls -lh "$PACKAGE_DIR"
echo ""
echo "See PACKAGE_INFO.txt for deployment instructions"
