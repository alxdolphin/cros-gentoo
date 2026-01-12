# Gentoo C201 USB Boot Instructions

## USB Contents

- Kernel: Linux 6.12.64 compiled for rk3288 veyron-speedy
- Root filesystem: Gentoo ARMv7 systemd stage3
- Root partition: ext4, PARTUUID=7999e767-a69e-49bf-8c9c-6e2b0b6f4e93

## Boot Steps

1. Ensure Developer Mode is enabled on the C201 (this should already be done)

2. Enable USB boot (if not already done):
   ```
   crossystem dev_boot_usb=1
   ```

3. Insert the USB drive into the C201

4. Boot from USB:
   - At the Developer Mode warning screen, press Ctrl+U
   - The system should boot from USB

5. Login:
   - Username: `root`
   - Password: `gentoo`

## Post-Boot Setup

### Generate Locales
```bash
locale-gen
```

### Configure Wi-Fi (if needed)
The Marvell Wi-Fi driver is built as a module. You may need firmware:
```bash
emerge linux-firmware
```

### Synchronize Portage
```bash
emerge --sync
```

## Partition Layout

| Partition | Type           | Size  | Purpose         |
|-----------|----------------|-------|-----------------|
| sdc1      | ChromeOS kernel| 64MB  | Signed kernel   |
| sdc2      | Linux data     | ~28GB | Root filesystem |

## Troubleshooting

### No boot / black screen
- Verify USB boot is enabled: `crossystem dev_boot_usb`
- Try a different USB port

### Kernel panic
- Check kernel cmdline matches root partition PARTUUID
- Boot parameters: `noinitrd console=tty1 earlyprintk loglevel=7 root=PARTUUID=7999e767-a69e-49bf-8c9c-6e2b0b6f4e93 rootfstype=ext4 rootwait rw`

### No network
- Enable and start systemd-networkd:
  ```bash
  systemctl enable --now systemd-networkd
  systemctl enable --now systemd-resolved
  ```
