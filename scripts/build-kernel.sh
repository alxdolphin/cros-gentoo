#!/bin/bash
# Build kernel for C201 (rk3288 veyron-speedy) using cross-compiler

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_DIR="${PROJECT_ROOT}/linux"
KERNEL_CONFIG="${PROJECT_ROOT}/.config.running"
OUTPUT_DIR="${PROJECT_ROOT}/kernel"

# Cross-compilation settings
export ARCH=arm
export CROSS_COMPILE="${CROSS_COMPILE:-armv7a-unknown-linux-gnueabihf-}"

# Check if we're in Codespace or have cross-compiler
if ! command -v ${CROSS_COMPILE}gcc &> /dev/null; then
    echo "Error: Cross-compiler not found: ${CROSS_COMPILE}gcc"
    echo "Please ensure CROSS_COMPILE is set correctly"
    exit 1
fi

cd "$KERNEL_DIR"

# Verify kernel source
if [ ! -f "Makefile" ]; then
    echo "Error: Kernel source not found at $KERNEL_DIR"
    echo "Run: scripts/setup-kernel-source.sh"
    exit 1
fi

# Copy config if .config doesn't exist
if [ ! -f ".config" ]; then
    if [ -f "$KERNEL_CONFIG" ]; then
        echo "Copying kernel config..."
        cp "$KERNEL_CONFIG" .config
    else
        echo "Error: No kernel config found"
        echo "Please create .config or ensure .config.running exists"
        exit 1
    fi
fi

# Prepare build
echo "=== Preparing kernel build ==="
echo "ARCH: $ARCH"
echo "CROSS_COMPILE: $CROSS_COMPILE"
echo "Kernel directory: $KERNEL_DIR"
echo ""

# Old config check
if [ -f ".config" ]; then
    echo "Checking for config changes..."
    make olddefconfig
fi

# Build kernel
echo "=== Building kernel ==="
echo "This may take a while..."
echo ""

# Get number of CPUs for parallel build
JOBS=$(nproc)
echo "Building with -j${JOBS} jobs"

make -j${JOBS} zImage dtbs

# Build modules
echo ""
echo "=== Building kernel modules ==="
make -j${JOBS} modules

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy kernel image
echo ""
echo "=== Copying build artifacts ==="
cp arch/arm/boot/zImage "$OUTPUT_DIR/zImage"
echo "✓ Copied zImage to $OUTPUT_DIR/"

# Copy device tree
if [ -f "arch/arm/boot/dts/rk3288-veyron-speedy.dtb" ]; then
    cp arch/arm/boot/dts/rk3288-veyron-speedy.dtb "$OUTPUT_DIR/rk3288-veyron-speedy.dtb"
    echo "✓ Copied device tree to $OUTPUT_DIR/"
fi

# Create FIT image (gentoo.itb) - required for ChromeOS verified boot
echo ""
echo "=== Creating FIT image ==="
FIT_SOURCE="${PROJECT_ROOT}/kernel/gentoo.its"
if [ -f "$FIT_SOURCE" ]; then
    cd "$OUTPUT_DIR"
    if command -v mkimage &> /dev/null; then
        # Copy .its file to output directory and adjust paths
        cp "$FIT_SOURCE" gentoo.its.tmp
        # mkimage will look for zImage and DTB in the same directory as the .its file
        mkimage -f gentoo.its.tmp gentoo.itb
        rm -f gentoo.its.tmp
        echo "✓ Created FIT image: gentoo.itb"
    else
        echo "Warning: mkimage not found. Install u-boot-tools to create FIT image."
        echo "FIT image creation skipped."
    fi
else
    echo "Warning: FIT source file not found: $FIT_SOURCE"
    echo "FIT image creation skipped."
fi

# Save config
cd "$KERNEL_DIR"
cp .config "$OUTPUT_DIR/config-$(date +%Y%m%d-%H%M%S)"
cp .config "$OUTPUT_DIR/config-latest"
echo "✓ Saved kernel config"

echo ""
echo "=== Kernel build complete ==="
echo "Build artifacts in: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "  1. Package kernel: scripts/package-kernel.sh"
echo "  2. Transfer to C201: See docs/KERNEL-BUILD.md"
echo ""
