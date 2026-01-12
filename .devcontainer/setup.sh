#!/bin/bash
# Setup script for Codespace environment
# Runs after container creation

set -e

echo "=== C201 Kernel Development Environment Setup ==="
echo ""

# Verify cross-compiler
echo "Checking cross-compiler..."
if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "✓ Cross-compiler found: $(arm-linux-gnueabihf-gcc --version | head -n1)"
else
    echo "✗ Cross-compiler not found!"
    exit 1
fi

# Display environment
echo ""
echo "Environment:"
echo "  ARCH: ${ARCH:-arm}"
echo "  CROSS_COMPILE: ${CROSS_COMPILE:-arm-linux-gnueabihf-}"
echo ""

# Check if kernel source exists
if [ -d "linux" ] && [ -f "linux/Makefile" ]; then
    echo "✓ Kernel source found at linux/"
    KERNEL_VERSION=$(grep "^VERSION\|^PATCHLEVEL" linux/Makefile | head -2 | sed 's/.*= *//' | tr '\n' '.' | sed 's/\.$//')
    echo "  Version: ${KERNEL_VERSION}"
else
    echo "ℹ Kernel source not found. Run: scripts/setup-kernel-source.sh"
fi

# Check for kernel config
if [ -f ".config.running" ]; then
    echo "✓ Kernel config found: .config.running"
elif [ -f "kernel/.config" ]; then
    echo "✓ Kernel config found: kernel/.config"
else
    echo "ℹ Kernel config not found"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Quick start:"
echo "  1. Setup kernel source:  scripts/setup-kernel-source.sh"
echo "  2. Configure kernel:     cd linux && make menuconfig"
echo "  3. Build kernel:         scripts/build-kernel.sh"
echo "  4. Package kernel:       scripts/package-kernel.sh"
echo ""
echo "See docs/CODESPACE-SETUP.md for detailed instructions"
