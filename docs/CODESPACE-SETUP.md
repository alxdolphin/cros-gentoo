# Codespace Setup

GitHub Codespace configuration for C201 kernel development.

## Configuration

The `.devcontainer/` directory contains:

- `devcontainer.json` - Codespace configuration
- `Dockerfile` - Container image with cross-compilation toolchain
- `setup.sh` - Post-creation setup script

## Container Environment

The container includes:

- ARM cross-compilation toolchain (armv7a-unknown-linux-gnueabihf)
- Kernel build dependencies (bc, bison, flex, libssl-dev, libelf-dev)
- Device tree compiler
- Build tools (make, gcc, git)

## Environment Variables

Set automatically in container:
- `ARCH=arm`
- `CROSS_COMPILE=armv7a-unknown-linux-gnueabihf-`

## First Run

After Codespace creation:

1. Verify cross-compiler:
   ```bash
   armv7a-unknown-linux-gnueabihf-gcc --version
   ```

2. Setup kernel source (git submodule):
   ```bash
   scripts/setup-kernel-source.sh
   ```
   This initializes the Linux kernel git submodule and checks out the configured version.

3. Verify setup:
   ```bash
   ls -la linux/
   git submodule status
   ```

## Customization

To modify the container:

1. Edit `.devcontainer/Dockerfile` for additional packages
2. Edit `.devcontainer/devcontainer.json` for VS Code settings
3. Rebuild container: Command Palette → "Rebuild Container"

## Troubleshooting

### Cross-compiler not found

Verify installation:
```bash
which armv7a-unknown-linux-gnueabihf-gcc
# For Ubuntu/Debian packages: dpkg -l | grep arm-linux-gnueabihf
# For Gentoo toolchain: armv7a-unknown-linux-gnueabihf-gcc
```

### Kernel source submodule fails

Check git submodule configuration:
```bash
cat .gitmodules
git submodule status
```

If submodule is not initialized:
```bash
git submodule update --init --recursive linux
cd linux
git checkout v6.12
```

### Build fails

Check environment variables:
```bash
echo $ARCH
echo $CROSS_COMPILE
```

Verify kernel config:
```bash
# Check if .config.running exists (default config)
ls -la .config.running

# Copy to kernel source if needed
cp .config.running linux/.config
cd linux && make olddefconfig
```
