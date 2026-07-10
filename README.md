# DELL-Latitude-5455-Ubuntu
My attempt at getting Ubuntu running on the DELL Latitude 5455 (Snapdragon X Plus X1P-64-100).

I don't know what I'm doing you can copy this at your own risk

## Note 
You should dual boot with windows in order to benefit from windows firmware updates and to extract firmware from windows partition

some links:

[Ubuntu Discourse](https://discourse.ubuntu.com/t/ubuntu-concept-snapdragon-x-elite/48800)

[Bug report](https://bugs.launchpad.net/ubuntu-concept/+bug/2121289)


| Feature | Status | Notes |
| ----------------------- | :---: |------------------------------------------------------------------------------------------------------------|
| WIFI/BT | 🟢 | Working |
| Battery Monitor | 🟢 | Working |
| Battery Charging | 🟢 | Working |
| Keyboard/Trackpad | 🟢 | Working |
| USB | 🟢 | Working |
| Display | 🟡 | Occasional freeze and no brightness control (use gnome extension)|
| Power Management | 🟡 | Usable but poor battery life |
| Fan Management | 🟡 | Fans only kick in when very hot or under high strain  |
| Sleep/suspend | 🟡 | Sometimes unable to wake from sleep/suspend |
| GPU | 🟡 | Acceleration seems to work, but doesn't seem energy efficient|
| Audio | 🟡 | EXPERIMENTAL Pipewire patch over 7455 topology
| Camera | 🟡 | Uncalibrated |

## Note on processor variants

The Dell latitude 5455 comes in two Snapdragon X Plus variants: X1P-64-100 & X1P-42-100

This repo is about the X1P-64-100 version. Which is similar to the Dell latitude 7455 (X1E-80-100)

I don't believe the following works for the X1P-42-100 variant, there was progress made in the [Bug report](https://bugs.launchpad.net/ubuntu-concept/+bug/2121289), check either mainline or latest [jglathe](https://github.com/jglathe/linux_ms_dev_kit/tree/jg/ubuntu-qcom-x1e-7.1.3-jg-0) repository for progress on this.


## DTB

Since recent kernel updates my custom dts doesn't work and its much simpler to just use the dell latitude 7455 dtb


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

Note: I'm using resolute-desktop-arm64+x1e-20260423_extended_jg.iso (from [here](https://drive.google.com/drive/folders/1sc_CpqOMTJNljfvRyLG-xdwB0yduje_O) by [jglathe](https://github.com/jglathe)) there may be a more recent version.

```bash
sudo mkdir -p /mnt/iso /mnt/usb

sudo mount -o loop ~/Downloads/resolute-desktop-arm64+x1e-20260423_extended_jg.iso /mnt/iso
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

## Step 4 — Find the Dell latitude 7455 Device Tree Blob (DTB)

Find the DTB:
```bash
unsquashfs -l /mnt/usb/casper/minimal.squashfs | grep -E "7455.dtb"
```
Extract the DTB: (change dtb path to whatever you found previously)
```bash
sudo unsquashfs -d /tmp/extracted_dtb /mnt/usb/casper/minimal.squashfs path/to/dtb/x1e80100-dell-latitude-7455.dtb
```

---

## Step 5 — Add the Device Tree Blob

Copy the 7455 DTB:
```bash
sudo cp /tmp/extracted_dtb/path/to/dtb/x1e80100-dell-latitude-7455.dtb /mnt/usb/
```

---

## Step 6 — Edit GRUB Configuration (Critical)

Open GRUB config:

```bash
sudo nano /mnt/usb/boot/grub/grub.cfg
```

### 6.1 Enable GRUB terminal output

Add **near the top of the file**, outside any `menuentry`:

```cfg
terminal_output gfxterm
```

### 6.2 Modify the Ubuntu menu entry

Add a new entry:

```cfg
menuentry "Try or Install Ubuntu" {
    set gfxpayload=keep
    linux   /casper/vmlinuz $cmdline --- quiet splash clk_ignore_unused pd_ignore_unused console=tty0
    initrd  /casper/initrd
    devicetree /x1e80100-dell-latitude-7455.dtb
}
```

Save and exit.

---

## Step 7 — Final Sync and Unmount

```bash
sync
sudo umount /mnt/usb
```
##  Generic Firmware Fixes 
If you lack a battery percentage indicator or specific platform sensors after initial boot, extract your system specifics:
```bash
sudo apt install qcom-firmware-extract
sudo qcom-firmware-extract
```
Then
```bash
sudo apt install ubuntu-x1e-settings
```

##  GPU

If acceleration fails to load, extract qcvss8380.mbn from your Windows driver partitions and save it directly under:
```bash
/lib/firmware/qcom/x1e80100/dell/latitude-7455/
```
## Sound

Warning: Attempt this at your own risk this could damage your speakers:

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp ~/Downloads/99-dell-5455-remap.conf ~/.config/pipewire/pipewire.conf.d/99-dell-5455-remap.conf
pactl set-default-sink $(pactl list sinks short | grep "Dell-5455-Stereo-Remap" | awk '{print $2}')
```
This works on my laptop but even max volume is very low.