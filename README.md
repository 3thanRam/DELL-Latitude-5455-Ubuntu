# DELL-Latitude-5455-Ubuntu
My attempt at getting Ubuntu running on the DELL Latitude 5455 (Snapdragon X Plus X1P-64-100).

### How to generate the DTB
Run these commands within your local kernel source tree to compile the device tree binary:

```bash
# Clone and navigate to the Snapdragon dts directory
git clone https://github.com/torvalds/linux.git
cd linux/arch/arm64/boot/dts/qcom/

# Preprocess the DTS to handle includes and macros
cpp -nostdinc -I . -I ../../../../include -I ../../../../../include -undef -x assembler-with-cpp x1p64100-dell-latitude-5455.dts x1p64100-dell-latitude-5455.dts.preprocessed

# Compile the preprocessed file into a DTB
dtc -I dts -O dtb -p 0x1000 x1p64100-dell-latitude-5455.dts.preprocessed -o x1p64100-dell-latitude-5455.dtb

# Install the DTB to your boot directory
mkdir -p /boot/dtbs/qcom/
sudo cp x1p64100-dell-latitude-5455.dtb /boot/dtbs/qcom/

```
---

## Modify an Ubuntu ISO Using a Writable USB

This method avoids rebuilding the ISO by creating a **fully writable UEFI USB layout**, copying the ISO contents, and then adding a custom **Device Tree Blob (DTB)**.

---

## Step 0 — Identify the USB Device

Plug in the USB drive, then run:

```bash
lsblk
```

Identify the device (example: `/dev/sdX`).

> ⚠️ **Important:** Use the disk (`/dev/sdX`), **not** a partition (`/dev/sdX1`).

---

## Step 1 — Wipe and Partition the USB

### 1.1 Create a new GPT

```bash
sudo parted /dev/sdX -- mklabel gpt
```

### 1.2 Create a single large FAT32 partition

```bash
sudo parted /dev/sdX -- mkpart primary fat32 1MiB 100%
sudo parted /dev/sdX -- set 1 esp on
```

### 1.3 Format the partition

```bash
sudo mkfs.vfat -F32 -n UBUNTU_USB /dev/sdX1
```

---

## Step 2 — Mount the ISO and USB

```bash
sudo mkdir -p /mnt/iso /mnt/usb

sudo mount -o loop ~/Downloads/plucky-desktop-arm64+x1e.iso /mnt/iso
sudo mount /dev/sdX1 /mnt/usb
```

---

## Step 3 — Copy ISO Contents to the USB (Critical)

This makes the USB **fully writable**.

```bash
sudo rsync -a /mnt/iso/ /mnt/usb/
sync
```

Unmount the ISO:

```bash
sudo umount /mnt/iso
```

---

## Step 4 — Add the Device Tree Blob (DTB)

Create the DTB directory and copy your DTB:

```bash
sudo mkdir -p /mnt/usb/casper/dtbs/qcom
sudo cp x1e80100-dell-latitude-7455.dtb /mnt/usb/casper/dtbs/qcom/
```

Verify:

```bash
ls /mnt/usb/casper/dtbs/qcom
```

---

## Step 5 — Edit GRUB Configuration (Critical)

Open GRUB config:

```bash
sudo nano /mnt/usb/boot/grub/grub.cfg
```

### 5.1 Enable GRUB terminal output

Add **near the top of the file**, outside any `menuentry`:

```cfg
terminal_output gfxterm
```

### 5.2 Modify the Ubuntu menu entry

Replace the existing entry with:

```cfg
menuentry "Try or Install Ubuntu" {
    set gfxpayload=keep
    devicetree /casper/dtbs/qcom/x1e80100-dell-latitude-7455.dtb
    linux   /casper/vmlinuz $cmdline --- quiet splash console=tty0
    initrd  /casper/initrd
}
```

Save and exit.

---

## Step 6 — Final Sync and Unmount

```bash
sync
sudo umount /mnt/usb
```

## Boot 

## Then copy x1p64100-dell-latitude-5455.dtb x1e80100-dell-latitude-7455.dtb and to /boot/dts/qcom/ and link the grub config to the 5455 dtb file

### Make a new GRUB entry

Create a custom GRUB script to ensure your Snapdragon-specific kernel and DTB are loaded first.

1. Create the script:
`sudo nano /etc/grub.d/09_snapdragon`
2. Paste the following configuration:

```sh
#!/bin/sh
set -e

# These variables are provided by the GRUB environment when update-grub runs
. /usr/share/grub/grub-mkconfig_lib

# Automatically detect the root device and UUID
root_device=$(grub-probe --target=device /)
root_uuid=$(grub-probe --device $root_device --target=fs_uuid)

echo "Found root UUID: $root_uuid" >&2

cat << EOF
menuentry 'Ubuntu Snapdragon' --class ubuntu --class gnu-linux --class gnu --class os {
    recordfail
    load_video
    insmod gzio
    insmod part_gpt
    insmod ext2
    
    # This searches for the drive dynamically at boot time
    search --no-floppy --fs-uuid --set=root $root_uuid
    
    echo "Loading DeviceTree..."
    devicetree /boot/dtbs/qcom/x1p64100-dell-latitude-5455.dtb
    
    echo "Loading Linux kernel..."
    linux   /boot/vmlinuz-6.17.0-8-qcom-x1e root=UUID=$root_uuid ro quiet splash console=tty0 crashkernel=2G-4G:320M,4G-32G:512M,32G-64G:1024M,64G-128G-:4096M \$vt_handoff
    
    echo "Loading initial ramdisk..."
    initrd  /boot/initrd.img-6.17.0-8-qcom-x1e
}
EOF

```

3. Make the script executable and update GRUB:

```bash
sudo chmod +x /etc/grub.d/09_snapdragon
sudo update-grub

```

##  Fix battery
Boot once into x1e80100-dell-latitude-7455.dtb (simply change the grub using e command when in grub menu) and then run:
```bash
sudo apt install qcom-firmware-extract
sudo qcom-firmware-extract
```
Then
```bash
sudo apt install ubuntu-x1e-settings
```
##  GPU stuff
get gen70500_sqe.fw and gen70500_gmu.bin from https://git.codelinaro.org/clo/linux-kernel/linux-firmware/-/blob/video-firmware/qcom/
Then mv them into /lib/firmware/qcom/x1e80100/

