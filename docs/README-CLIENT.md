# NBD Client Configuration

## Overview

This machine operates as an NBD client, connecting to a remote NBD server to access the C201 USB boot image over the network.

## Quick Commands

```bash
# Load nbd kernel module (if needed)
modprobe nbd

# Connect to server (replace SERVER_IP with actual IP)
nbd-client <SERVER_IP> 10809 /dev/nbd0

# Example:
nbd-client 192.168.1.100 10809 /dev/nbd0

# Check connection
lsblk /dev/nbd0

# Disconnect
nbd-client -d /dev/nbd0
```

## Prerequisites

1. Install NBD client:
   ```bash
   emerge net-misc/nbd  # Gentoo
   # or: apt-get install nbd-client  # Debian/Ubuntu
   ```

2. Obtain server IP address from network administrator

3. Verify server is running (confirm with server administrator)

## Example Session

```bash
# 1. Load nbd kernel module (if needed)
modprobe nbd

# 2. Connect to server
nbd-client 192.168.1.100 10809 /dev/nbd0

# 3. View partitions
lsblk /dev/nbd0

# 4. Use the image (e.g., mount partition 2)
mount /dev/nbd0p2 /mnt
ls /mnt

# 5. Unmount and disconnect
umount /mnt
nbd-client -d /dev/nbd0
```

## Additional Documentation

- `NBD-SETUP.md` - Detailed NBD setup and usage
- `README-NBD.md` - NBD quick start guide

