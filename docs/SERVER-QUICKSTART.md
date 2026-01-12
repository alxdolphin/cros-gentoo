# Server Quick Start

## Server Computer Configuration

Server computer requirements: USB image or recovery image file available.

### Installation

```bash
emerge net-misc/nbd  # Gentoo
# or: apt-get install nbd-server  # Debian/Ubuntu
```

### Start Server

```bash
# Using config file (if available)
nbd-server -C docs/nbd.conf

# Or direct command with recovery image
nbd-server 10809 /path/to/c201-preconfigured.img

# Or if USB device is attached
nbd-server 10809 /dev/sdb  # Replace /dev/sdb with your USB device
```

### Verify Server Status

```bash
# Check if server is running
ps aux | grep nbd-server

# Check if port is listening
netstat -tlnp | grep 10809
```

### Obtain IP Address

```bash
hostname -I
# or
ip addr show
```

Share this IP address with the client machine.

### Configure Firewall

If firewall is enabled:

```bash
# iptables
iptables -A INPUT -p tcp --dport 10809 -j ACCEPT

# firewalld
firewall-cmd --add-port=10809/tcp --permanent && firewall-cmd --reload

# ufw
ufw allow 10809/tcp
```

### Stop Server

```bash
killall nbd-server
```

## Additional Documentation

See `SERVER-SETUP.md` for detailed instructions.

