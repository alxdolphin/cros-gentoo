#!/bin/bash
# Setup kernel source using git submodule

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_VERSION="${KERNEL_VERSION:-v6.12}"

cd "$PROJECT_ROOT"

echo "=== Setting up kernel source ==="
echo "Kernel version: ${KERNEL_VERSION}"

# Check if kernel source already exists
if [ -d "linux" ] && [ -f "linux/Makefile" ]; then
    echo "✓ Kernel source already exists at linux/"
    CURRENT_VERSION=$(grep "^VERSION\|^PATCHLEVEL" linux/Makefile | head -2 | sed 's/.*= *//' | tr '\n' '.' | sed 's/\.$//')
    echo "  Current version: ${CURRENT_VERSION}"
    
    read -p "Update kernel source? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing kernel source"
    else
        echo "Updating kernel submodule..."
        git submodule update --init --recursive linux
        cd linux
        git checkout ${KERNEL_VERSION}
        cd ..
    fi
    exit 0
fi

# Initialize and update submodule
echo "Initializing and updating git submodule..."
if ! git submodule update --init --recursive linux 2>/dev/null; then
    # Fallback: submodule not registered in git index, clone manually
    echo "Submodule not in git index, cloning repository directly..."
    KERNEL_URL=$(git config --file .gitmodules --get submodule.linux.url)
    if [ -z "$KERNEL_URL" ]; then
        KERNEL_URL="https://github.com/torvalds/linux.git"
    fi
    git clone --depth 1 --branch ${KERNEL_VERSION} "$KERNEL_URL" linux || \
    git clone "$KERNEL_URL" linux
    cd linux
    git checkout ${KERNEL_VERSION}
    cd ..
else
    # Checkout specific version
    cd linux
    echo "Checking out ${KERNEL_VERSION}..."
    git checkout ${KERNEL_VERSION}
    cd ..
fi

echo "✓ Kernel source ready at linux/"

# Copy kernel config if it exists
if [ -f ".config.running" ]; then
    echo "Copying kernel config..."
    cp .config.running linux/.config
    echo "✓ Kernel config copied to linux/.config"
elif [ -f "kernel/.config" ]; then
    echo "Copying kernel config..."
    cp kernel/.config linux/.config
    echo "✓ Kernel config copied to linux/.config"
fi

echo ""
echo "=== Kernel source setup complete ==="
echo "Kernel source location: $(pwd)/linux"
echo ""
