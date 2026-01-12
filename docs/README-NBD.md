# Quick Start: NBD Network Boot Setup

## Overview

Network Block Device (NBD) setup for sharing the C201 recovery image over the network.

## Files

- `nbd.conf` - NBD server configuration file
- `NBD-SETUP.md` - Detailed setup and usage instructions

## Prerequisites

Download the recovery image from GitHub Releases or set `C201_IMAGE` environment variable.

## Quick Start

### Install NBD

If not already installed:

```bash
# On Gentoo
emerge net-misc/nbd

# Or on your distribution
# Debian/Ubuntu: apt-get install nbd-server nbd-client
# Fedora: dnf install nbd
# Arch: pacman -S nbd
```

### Start NBD Server

```bash
cd /root/c201-usb

# Option A: Using config file
nbd-server -C nbd.conf

# Option B: Direct command (specify image path)
nbd-server 10809 /path/to/c201-preconfigured.img
```

### Test Connection

Test connection locally:

```bash
# Load nbd kernel module (if needed)
modprobe nbd

# Test connection
nbd-client localhost 10809 /dev/nbd0
lsblk /dev/nbd0
nbd-client -d /dev/nbd0  # Disconnect
```

### Connect from C201

```bash
# On the C201, load nbd module
modprobe nbd

# Connect to server (replace SERVER_IP with actual IP)
nbd-client <SERVER_IP> 10809 /dev/nbd0

# Now /dev/nbd0 is your USB image over the network
```

## Troubleshooting

### Port already in use
```bash
# Check what's using the port
netstat -tlnp | grep 10809
# or
ss -tlnp | grep 10809

# Kill existing nbd-server
killall nbd-server
```

### Device not found
```bash
# Load nbd kernel module
modprobe nbd

# Check if device exists
ls -l /dev/nbd*
```

### Connection refused
- Check firewall: `iptables -L -n | grep 10809`
- Verify server is running: `ps aux | grep nbd-server`
- Check server IP address

## Security Note

NBD is not encrypted by default. Use on trusted networks only, or use SSH tunneling:

```bash
# Create SSH tunnel
ssh -L 10809:localhost:10809 user@server

# Connect through tunnel
nbd-client localhost 10809 /dev/nbd0
```

## More Information

See `NBD-SETUP.md` for detailed documentation, security considerations, and advanced usage.
