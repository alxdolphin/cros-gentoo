# NBD (Network Block Device) Setup for C201 USB Image

This setup allows you to share the USB boot image over the network using NBD (Network Block Device), so you can boot the C201 from the network instead of a physical USB drive.

## Installation

### On Gentoo (Server/Development Machine)

```bash
emerge net-misc/nbd
```

Or install on other distributions:
- **Debian/Ubuntu**: `apt-get install nbd-server nbd-client`
- **Fedora/RHEL**: `dnf install nbd`
- **Arch**: `pacman -S nbd`

## Configuration File

The configuration file `nbd.conf` is located in `/root/c201-usb/nbd.conf`

### Configuration Details

- **Port**: 10809 (default NBD port)
- **Export**: Recovery image path (set via `C201_IMAGE` or update `nbd.conf`)
- **Mode**: Read-only (prevents corruption during boot)
- **Size**: 4 GB (automatically detected)

## Starting the NBD Server

### Method 1: Using the configuration file

```bash
cd /root/c201-usb
nbd-server -C nbd.conf
```

### Method 2: Command line

```bash
# Using recovery image
nbd-server 10809 /path/to/c201-preconfigured.img
```

### Method 3: Systemd service (if available)

```bash
# Copy config to system directory
sudo cp nbd.conf /etc/nbd-server/conf.d/c201-usb.conf

# Start and enable service
sudo systemctl start nbd-server
sudo systemctl enable nbd-server
```

## Connecting from Client (C201)

### Option 1: Using nbd-client on the C201

First, you'll need nbd-client on the C201. Then:

```bash
# Connect to NBD server
nbd-client <SERVER_IP> 10809 /dev/nbd0

# Now /dev/nbd0 will be your USB image over the network
# You can use it like a regular block device
```

### Option 2: Boot from Network Block Device

If your bootloader supports network booting, you can configure it to boot from the NBD device.

## Security Considerations

NBD by default does not use encryption or authentication. For security:

1. Use on trusted network only
2. Use firewall rules to restrict access:
   ```bash
   # Allow only specific IP (replace with C201 IP)
   iptables -A INPUT -p tcp --dport 10809 -s <C201_IP> -j ACCEPT
   iptables -A INPUT -p tcp --dport 10809 -j DROP
   ```
3. Consider using NBD over SSH tunnel for encryption:
   ```bash
   # On server
   ssh -L 10809:localhost:10809 user@server
   
   # On client
   nbd-client localhost 10809 /dev/nbd0
   ```

## Testing the Setup

1. Start the server:
   ```bash
   cd /root/c201-usb
   nbd-server -C nbd.conf
   ```

2. Check if server is running:
   ```bash
   netstat -tlnp | grep 10809
   # or
   ss -tlnp | grep 10809
   ```

3. Test connection locally (if nbd-client is installed):
   ```bash
   nbd-client localhost 10809 /dev/nbd0
   lsblk /dev/nbd0
   nbd-client -d /dev/nbd0  # Disconnect
   ```

## Troubleshooting

### Server won't start
- Check if port 10809 is already in use: `netstat -tlnp | grep 10809`
- Check file permissions: ensure nbd-server can read the image file
- Check logs: `/var/log/syslog` or `journalctl -u nbd-server`

### Connection refused
- Check firewall settings
- Verify server IP address
- Check if server is running: `ps aux | grep nbd-server`

### Permission denied
- Ensure nbd-server has read access to the image file
- On some systems, nbd-server needs to run as root

## Alternative: qemu-nbd

If QEMU is installed, `qemu-nbd` may be used as an alternative:

```bash
# Export recovery image over NBD
qemu-nbd --format=raw --export-name=c201-recovery --port=10809 /path/to/c201-preconfigured.img

# Connect from client
nbd-client <SERVER_IP> 10809 /dev/nbd0
```

## Notes

- The image is exported as read-only to prevent corruption
- The image is 4 GB in size
- Network performance depends on network speed
- For best performance, use Gigabit Ethernet
- Booting over network may be slower than local USB boot
