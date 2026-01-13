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

# Copy FIT image if available
if [ -f "${KERNEL_OUTPUT}/gentoo.itb" ]; then
    echo "Copying FIT image..."
    cp "${KERNEL_OUTPUT}/gentoo.itb" .
fi

# Copy kernel.flags if available
KERNEL_FLAGS="${PROJECT_ROOT}/kernel/kernel.flags"
if [ -f "$KERNEL_FLAGS" ]; then
    echo "Copying kernel.flags..."
    cp "$KERNEL_FLAGS" .
else
    echo "Warning: kernel.flags not found at $KERNEL_FLAGS"
fi

# Sign and pack kernel for ChromeOS verified boot (if FIT image exists)
if [ -f "gentoo.itb" ] && [ -f "kernel.flags" ]; then
    echo ""
    echo "=== Signing and packing kernel ==="
    
    # Check for futility/vbutil_kernel
    if command -v futility &> /dev/null; then
        VBUTIL_CMD="futility vbutil_kernel"
    elif command -v vbutil_kernel &> /dev/null; then
        VBUTIL_CMD="vbutil_kernel"
    else
        echo "Warning: futility/vbutil_kernel not found. Install vboot-utils."
        echo "Kernel signing skipped. Unsigned kernel may not boot on ChromeOS devices."
        VBUTIL_CMD=""
    fi
    
    if [ -n "$VBUTIL_CMD" ]; then
        # Check for ChromeOS devkeys (required for signing)
        KEYBLOCK="/usr/share/vboot/devkeys/kernel.keyblock"
        SIGNPRIVATE="/usr/share/vboot/devkeys/kernel_data_key.vbprivk"
        BOOTLOADER="/usr/share/vboot/devkeys/u-boot-dtb.bin"
        
        if [ -f "$KEYBLOCK" ] && [ -f "$SIGNPRIVATE" ] && [ -f "$BOOTLOADER" ]; then
            echo "Signing kernel with ChromeOS devkeys..."
            $VBUTIL_CMD --pack vmlinux.kpart \
                --keyblock "$KEYBLOCK" \
                --signprivate "$SIGNPRIVATE" \
                --version 1 \
                --vmlinuz gentoo.itb \
                --config kernel.flags \
                --arch arm \
                --bootloader "$BOOTLOADER" 2>&1
            
            if [ -f "vmlinux.kpart" ]; then
                echo "✓ Created signed kernel partition: vmlinux.kpart"
            else
                echo "Warning: Kernel signing failed"
            fi
        else
            echo "Warning: ChromeOS devkeys not found."
            echo "Expected locations:"
            echo "  - $KEYBLOCK"
            echo "  - $SIGNPRIVATE"
            echo "  - $BOOTLOADER"
            echo "Kernel signing skipped. Install chromeos-devkeys or provide custom keys."
        fi
    fi
fi

# Create info file
cat > PACKAGE_INFO.txt <<EOF
C201 Kernel Package
Generated: $(date)
Kernel Version: $(grep "^VERSION\|^PATCHLEVEL" "${KERNEL_DIR}/Makefile" | head -2 | sed 's/.*= *//' | tr '\n' '.' | sed 's/\.$//')
Build Host: $(hostname)
Cross Compiler: ${CROSS_COMPILE:-armv7a-unknown-linux-gnueabihf-}

Files:
- zImage: Kernel image for rk3288-veyron-speedy
- rk3288-veyron-speedy.dtb: Device tree blob
- gentoo.itb: FIT image (kernel + DTB) for ChromeOS verified boot
- vmlinux.kpart: Signed kernel partition image (if signing succeeded)
- kernel.flags: Kernel boot parameters
- kernel.config: Kernel configuration used

To deploy:
1. If vmlinux.kpart exists (signed kernel):
   - Copy vmlinux.kpart to kernel partition: dd if=vmlinux.kpart of=/dev/sdX1
2. Otherwise (unsigned kernel):
   - Copy zImage and rk3288-veyron-speedy.dtb to C201
   - Follow instructions in docs/KERNEL-BUILD.md
EOF

echo "✓ Package created in: $PACKAGE_DIR"
echo ""
echo "Package contents:"
ls -lh "$PACKAGE_DIR"
echo ""
echo "See PACKAGE_INFO.txt for deployment instructions"
