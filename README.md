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

### Make a new GRUB entry

Create a custom GRUB script to ensure your Snapdragon-specific kernel and DTB are loaded first.

1. Create the script:
`sudo nano /etc/grub.d/09_snapdragon`
2. Paste the following configuration:

```sh
#!/bin/sh
exec tail -n +3 $0
menuentry 'Ubuntu Snapdragon' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-05b41e37-dbcf-4eb7-9703-a3c03ab9080e' {
        recordfail
        load_video
        gfxmode $linux_gfx_mode
        insmod gzio
        if [ x$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
        insmod part_gpt
        insmod ext2
        search --no-floppy --fs-uuid --set=root 05b41e37-dbcf-4eb7-9703-a3c03ab9080e
        devicetree /boot/dtbs/qcom/x1p64100-dell-latitude-5455.dtb
        linux   /boot/vmlinuz-6.17.0-8-qcom-x1e root=UUID=05b41e37-dbcf-4eb7-9703-a3c03ab9080e ro  quiet splash console=tty0 crashkernel=2G-4G:320M,4G-32G:512M,32G-64G:1024M,64G-128G-:4096M $vt_handoff
        initrd  /boot/initrd.img-6.17.0-8-qcom-x1e
}

```

3. Make the script executable and update GRUB:

```bash
sudo chmod +x /etc/grub.d/09_snapdragon
sudo update-grub

```
