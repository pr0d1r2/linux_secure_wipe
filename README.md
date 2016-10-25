# linux_secure_wipe

Prepare disks for LUKS encryption in secure (and fast way). Tested on
Intel processor with AES instructions.

## usage

To prepare disk for space cleaning firstly run:

```
time sh securely_wipe_devices_luks_headers.sh /dev/sda /dev/sdb # ... /dev/sdz
```

Then to securely wipe space use (It wipes 110-120MB/s on Intel C2750 CPU):

```
time sh securely_wipe_devices.sh /dev/sda /dev/sdb # ... /dev/sdz
```
