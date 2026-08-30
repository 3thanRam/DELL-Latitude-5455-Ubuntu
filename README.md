# DELL-Latitude-5455-Ubuntu
My attempt at getting Ubuntu running on the DELL Latitude 5455 (Snapdragon X Plus X1P-64-100).

I don't know what I'm doing you can copy this at your own risk

## Note 
You should dual boot with windows in order to benefit from windows firmware updates and to extract firmware from windows partition

some links:

[Ubuntu Discourse](https://discourse.ubuntu.com/t/ubuntu-concept-snapdragon-x-elite/48800)

[Bug report](https://bugs.launchpad.net/ubuntu-concept/+bug/2121289)

[jglathe/linux_ms_dev_kit](https://github.com/jglathe/linux_ms_dev_kit)

[IRC aarch64-laptops](https://oftc.catirclogs.org/aarch64-laptops/)

[qcom-laptops](https://github.com/linux-msm/laptops-kernel/tree/qcom-laptops)

| Feature | Status | Notes |
| ----------------------- | :---: |------------------------------------------------------------------------------------------------------------|
| WIFI/BT | 🟢 | Working |
| Battery Monitor | 🟢 | Working |
| Battery Charging | 🟢 | Working |
| Keyboard/Trackpad | 🟢 | Working |
| USB | 🟢 | Working |
| Sleep/suspend | 🟢 | Working |
| [Camera](#camera-calibration) | 🟢 | Working |
| [Display](#display) | 🟢 | Fully working on [this kernel](https://github.com/jglathe/linux_ms_dev_kit/tree/jg/ubuntu-qcom-x1e-7.2.y)|
| [Fan Management](#ec-thermal--fan-management)| 🟢 | EXPERIMENTAL thermal management and fan control |
| [Audio](#audio) | 🟢 | EXPERIMENTAL use of 7455 topology|
| Power Management | 🟡 | Usable but sub-Windows battery life |
| [GPU](#gpu)| 🟡 | Acceleration seems to work, but doesn't seem energy efficient|

## Note on processor variants

The Dell latitude 5455 comes in two Snapdragon X Plus variants: X1P-64-100 & X1P-42-100

This repo is about the X1P-64-100 version. Which is similar to the Dell latitude 7455 (X1E-80-100)

I don't believe the following works for the X1P-42-100 variant, there was progress made in the [Bug report](https://bugs.launchpad.net/ubuntu-concept/+bug/2121289), check either mainline or latest [jglathe](https://github.com/jglathe/linux_ms_dev_kit/tree/jg/ubuntu-qcom-x1e-7.1.3-jg-0) repository for progress on this.


## DTB

Since recent kernel updates my custom dts doesn't work and its much simpler to just use the dell latitude 7455 dtb

Update: If using [this kernel](https://github.com/jglathe/linux_ms_dev_kit/tree/jg/ubuntu-qcom-x1e-7.2.y) then you can use x1p64100-dell-latitude-5455.dtb which adds display brightness control but at the time of writing I don't believe there is an ISO based on this kernel available so I would use still use the 7455 dtb for initial install then switch to the 5455.

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

## Camera calibration

Ubuntu's packaged libcamera 0.7.0 works, but newer upstream 0.7.2 contains important Simple/Software ISP fixes and produces better results.

I therefore use a locally built libcamera 0.7.2.

For image tuning, I currently use the OV02E10 tuning file from the [Samsung Galaxy Book Linux fixes project](https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes/blob/main/webcam-fix-book5/ov02e10.yaml) as a starting point:

This significantly improves colour reproduction compared with the default/uncalibrated Simple IPA output.

The sensor is the same OmniVision OV02E10, but the tuning was created for a Samsung Galaxy Book 5 Pro, so it should be considered provisional rather than a Dell-specific calibration. The black level has been independently verified on the Latitude 5455 at 64 RAW10 codes (4096 in libcamera's 16-bit representation).

A separate local libcamera change is also currently required to avoid flicker under 50 Hz lighting by limiting the maximum exposure to approximately 30 ms:
In:
```bash
src/ipa/simple/soft_simple.cpp
```
change:
```bash
context_.configuration.agc.exposureMax =
    exposureInfo.max().get<int32_t>();
```
to:
```bash
context_.configuration.agc.exposureMax =
    std::min(exposureInfo.max().get<int32_t>(), 2023);
```

## Audio

> **Warning**
>
> The audio support described below is experimental and was tested only on my Dell Latitude 5455. Incorrect audio routing or mixer configuration can potentially result in unexpectedly loud output. Keep the volume low while testing and make sure you have a known-good DTB/kernel available to boot if something goes wrong.

### HDMI / DisplayPort audio

On the Latitude 5455, the DisplayPort controllers already expose audio support, but the sound card was missing the ASoC DAI links connecting the AudioReach DisplayPort endpoints to the display controllers.

Add the following to the `&sound` node:

```dts
&sound {
        model = "X1E80100-Dell-Latitude-5455";

        displayport-0-dai-link {
                link-name = "DisplayPort0 Playback";

                codec {
                        sound-dai = <&mdss_dp0>;
                };

                cpu {
                        sound-dai = <&q6apmbedai DISPLAY_PORT_RX_0>;
                };

                platform {
                        sound-dai = <&q6apm>;
                };
        };

        displayport-1-dai-link {
                link-name = "DisplayPort1 Playback";

                codec {
                        sound-dai = <&mdss_dp1>;
                };

                cpu {
                        sound-dai = <&q6apmbedai DISPLAY_PORT_RX_1>;
                };

                platform {
                        sound-dai = <&q6apm>;
                };
        };
};
```

After booting the updated DTB, the corresponding ALSA jack controls should appear:

```bash
amixer -c 0 controls | grep -E 'DP[01] Jack'
```

For example:

```text
numid=168,iface=CARD,name='DP0 Jack'
numid=173,iface=CARD,name='DP1 Jack'
```

With a display connected, the appropriate jack should report `on`:

```bash
amixer -c 0 cget "iface=CARD,name='DP0 Jack'"
amixer -c 0 cget "iface=CARD,name='DP1 Jack'"
```

### AudioReach topology

The 5455 currently uses a topology compatible with the Latitude 7455 topology.

If a 5455 topology is not already installed, the 7455 topology can currently be used as a workaround:

```bash
sudo cp \
    qcom/x1e80100/X1E80100-Dell-Latitude-7455-tplg.bin.zst \
    qcom/x1e80100/X1E80100-Dell-Latitude-5455-tplg.bin.zst

sudo cp \
    qcom/x1e80100/X1E80100-Dell-Latitude-7455-tplg.bin \
    qcom/x1e80100/X1E80100-Dell-Latitude-5455-tplg.bin
```

The topology I tested exposes:

```text
DISPLAY_PORT_RX_0 Audio Mixer MultiMedia1
DISPLAY_PORT_RX_1 Audio Mixer MultiMedia1
```

but does **not** expose `DISPLAY_PORT_RX_2`.

### ALSA UCM configuration

There are two separate issues with the current 5455 UCM configuration.

#### 1. The 5455 profile may not be selected

On my system ALSA originally fell back to the generic Dell match in:

```text
/usr/share/alsa/ucm2/conf.d/x1e80100/x1e80100.conf
```

which selected:

```text
Dell-Latitude-7455.conf
Latitude7455-HiFi.conf
```

instead of the 5455 configuration.

This can be verified with:

```bash
strace -f -e trace=%file \
    -o /tmp/ucm.trace \
    alsaucm -c hw:0 dump text >/dev/null 2>&1

grep -E 'Latitude5455|Latitude7455|Dell-Latitude' /tmp/ucm.trace
```

On my machine ALSA looked for the exact card-specific file:

```text
/usr/share/alsa/ucm2/conf.d/x1e80100/DellInc.-Latitude5455-0H02CK.conf
```

I created this selector:

```text
Syntax 4

Include.latitude5455.File "/Qualcomm/x1e80100/Dell-Latitude-5455.conf"
```

This causes ALSA to use:

```text
Dell-Latitude-5455.conf
Latitude5455-HiFi.conf
```

instead of falling back to the 7455 configuration.

The exact filename may depend on the card long name. Check yours with:

```bash
cat /proc/asound/card0/id
cat /proc/asound/cards
alsaucm listcards
```

#### 2. The 5455 HiFi file needs adjusting

My hardware exposes only:

```text
DISPLAY_PORT_RX_0
DISPLAY_PORT_RX_1

DP0 Jack
DP1 Jack
```

so I removed all references to:

```text
DISPLAY_PORT_RX_2
DP2 Jack
HDMI2
```

from:

```text
/usr/share/alsa/ucm2/Qualcomm/x1e80100/Latitude5455-HiFi.conf
```

I kept the working Latitude 7455 four-speaker configuration and added two DisplayPort devices using `MultiMedia1`:

```text
HDMI0 -> DISPLAY_PORT_RX_0 -> DP0 Jack
HDMI1 -> DISPLAY_PORT_RX_1 -> DP1 Jack
```

The resulting UCM device list should contain:

```bash
alsaucm -n -b - <<'EOF'
open hw:0
set _verb HiFi
list _devices
EOF
```

with output including:

```text
Speaker
Headphones
Headset
Mic
HDMI0
HDMI1
```

### PipeWire

After changing UCM configuration, restart WirePlumber/PipeWire:

```bash
systemctl --user restart wireplumber pipewire pipewire-pulse
```

Then check:

```bash
wpctl status
```

A connected display should appear as something similar to:

```text
Built-in Audio USB/DisplayPort 0 playback
```

The UCM card may expose separate profiles for headphones and DisplayPort, for example:

```text
HiFi (HDMI0, Headset, Mic, Speaker)
HiFi (HDMI1, Headset, Mic, Speaker)
HiFi (Headphones, Headset, Mic, Speaker)
```

The appropriate profile can currently be selected manually, for example:

```bash
pactl set-card-profile alsa_card.platform-sound \
    'HiFi (HDMI0, Headset, Mic, Speaker)'
```

### Current status

On my Latitude 5455:

- Internal speakers work.
- Internal microphone works.
- Headset microphone detection works.
- `DP0 Jack` / `DP1 Jack` are created after adding the DT DAI links.
- DisplayPort hotplug detection works.
- HDMI/DisplayPort audio appears in PipeWire.
- Audio over USB-C DisplayPort/HDMI works after selecting the correct UCM profile.
- Headphone output is still being investigated; jack detection works, but ACP/UCM mixer handling still needs cleanup.

This is therefore still experimental rather than a finished upstream-quality audio configuration.

## Display

Thanks to the amazing [jglathe](https://github.com/jglathe) and their latest [kernel](https://github.com/jglathe/linux_ms_dev_kit/tree/jg/ubuntu-qcom-x1e-7.2.y) we can control the display brightness without relying on alpha/ software brightness hack. 

This requires using their custom dell latitude 5455 x1p64100 dtb. This may require copying firmware (from /lib/firmware/qcom/x1e80100/dell/latitude-7455/
 and windows partition) into a new /lib/firmware/qcom/x1e80100/dell/latitude-5455/ directory
 

However for it to work on my machine I needed to add this line to the dts:
```bash
&pmk8550_pwm {
        status = "okay";
};
```
Then recompiling.

The default brightness made it seem like the screen was off but using brightnessctl through ssh I was able to increase the brightness then after login everything worked great. 


## EC Thermal / Fan Management

> **Warning**
>
> This is experimental support based on the Dell XPS 13 9345 EC driver and the Dell Thena device-tree implementation.
> Test at your own risk.

### Overview

The Dell Latitude 5455 uses a Dell Embedded Controller (EC) for platform thermal management and fan control.

Linux does not directly set fan PWM with this implementation. Instead:

1. Linux reads board thermistors through the Qualcomm PMIC ADC.
2. The `dell-xps-ec` driver forwards those temperatures to the EC every 100 ms.
3. The EC applies its own fan-control policy.

The stock kernel configuration used here was missing some of the required support, so three pieces are needed:

1. Device-tree support for the Dell EC and thermistors
2. Qualcomm PMIC ADC5 Gen3 support
3. The Dell EC driver

---

### 1. Device-tree EC support

The EC support is based on [Val Packett](https://github.com/valpackett)'s [Thena EC implementation](https://github.com/valpackett/linux-qclaptops/commit/28a7eb40940c1d9f61be221e4f5832c8705bcca7) :

```text
arm64: dts: qcom: x1-dell-thena: add EC
```

The EC is connected over I2C at address:

```text
0x3b
```

and uses GPIO66 for its interrupt.

The EC node is approximately:

```dts
embedded-controller@3b {
        compatible = "dell,xps13-9345-ec";
        reg = <0x3b>;

        interrupts-extended = <&tlmm 66 IRQ_TYPE_LEVEL_LOW>;

        pinctrl-0 = <&ec_int_n_default>;
        pinctrl-names = "default";

        io-channels = <&pmk8550_adc_tm ...>;
        io-channel-names = "sys_therm0", "sys_therm1", "sys_therm2",
                           "sys_therm3", "sys_therm4", "sys_therm5",
                           "sys_therm6";

        wakeup-source;
};
```

GPIO65 should remain reserved because it is the EC reset line.

### Compatibility changes for this kernel tree

The Thena EC patch was written against a slightly different DT-binding layout.

The PM8350 ADC7 wrapper originally included:

```c
#include <dt-bindings/iio/qcom,spmi-vadc.h>
```

but this kernel tree uses the newer path:

```c
#include <dt-bindings/iio/adc/qcom,spmi-vadc.h>
```

The original Thena patch also references:

```dts
&pmk8550_vadc
```

while this kernel tree labels the same ADC controller as:

```dts
&pmk8550_adc_tm
```

Therefore the Thena EC additions must use:

```dts
&pmk8550_adc_tm
```

instead.

---

### 2. Enable Qualcomm ADC5 Gen3

The PMK8550 ADC controller on this kernel tree is described as:

```dts
compatible = "qcom,spmi-adc5-gen3";
```

The installed kernel configuration originally had:

```text
# CONFIG_QCOM_SPMI_ADC5_GEN3 is not set
```

The required driver is:

```text
CONFIG_QCOM_SPMI_ADC5_GEN3=m
```

which builds:

```text
qcom-spmi-adc5-gen3.ko
```

Without this driver, the EC remains in deferred probe because its IIO thermistor channels do not exist.

A working setup should expose an IIO device similar to:

```text
/sys/bus/iio/devices/iio:device0
```

with:

```text
name: spmi-adc5-gen3
```

For example:

```bash
cat /sys/bus/iio/devices/iio:device0/name
```

should return:

```text
spmi-adc5-gen3
```

---

### 3. Dell EC driver

The EC driver is:

```text
drivers/platform/arm64/dell-xps-ec.c
```

and matches:

```text
compatible = "dell,xps13-9345-ec";
```

The driver periodically reads board thermistors through IIO and sends the temperatures to the EC every 100 ms.

A successful probe produces:

```text
dell-xps-ec 5-003b: Started periodic temperature reporting to EC every 100 ms
```

The driver should also bind to:

```text
/sys/bus/i2c/drivers/dell-xps-ec/5-003b
```

---

### Latitude 5455 thermistor differences

On the Latitude 5455, five of the seven thermistor channels produce plausible changing temperatures:

```text
sys_therm1
sys_therm2
sys_therm3
sys_therm4
sys_therm5
```

Two channels appear to be invalid or unconnected on this model:

```text
sys_therm0 = 130.048 C
sys_therm6 = -40.960 C
```

Both values remain fixed and appear to represent ADC saturation / endpoint values rather than real temperatures.

These two channels should therefore not be forwarded to the EC.

### Safe Latitude 5455 reporting table

The original driver contains:

```c
static const struct {
        const char *name;
        u8 cmd;
} dell_xps_ec_therms[] = {
        { "sys_therm0", 0x02 },
        { "sys_therm1", 0x03 },
        { "sys_therm2", 0x04 },
        { "sys_therm3", 0x05 },
        { "sys_therm4", 0x06 },
        { "sys_therm5", 0x07 },
        { "sys_therm6", 0x08 },
};
```

For the Latitude 5455, use:

```c
static const struct {
        const char *name;
        u8 cmd;
} dell_xps_ec_therms[] = {
        { "sys_therm1", 0x03 },
        { "sys_therm2", 0x04 },
        { "sys_therm3", 0x05 },
        { "sys_therm4", 0x06 },
        { "sys_therm5", 0x07 },
};
```

The EC thermistor profile itself should remain unchanged for now.

---

### 4. Build the ADC5 Gen3 module externally

If the running kernel was built without:

```text
CONFIG_QCOM_SPMI_ADC5_GEN3
```

the driver can be built as an external module against the installed kernel headers.

Required source files:

```text
drivers/iio/adc/qcom-spmi-adc5-gen3.c
include/linux/iio/adc/qcom-adc5-gen3-common.h
```

Example external-module Makefile:

```make
obj-m := qcom-spmi-adc5-gen3.o

ccflags-y += -I$(src)/include
```

Build with:

```bash
make -C /lib/modules/$(uname -r)/build M="$PWD" modules
```

Verify the module matches the running kernel:

```bash
modinfo ./qcom-spmi-adc5-gen3.ko | grep vermagic
uname -r
```

Install:

```bash
sudo cp qcom-spmi-adc5-gen3.ko \
  /lib/modules/$(uname -r)/extra/

sudo depmod -a
```

Load:

```bash
sudo modprobe qcom-spmi-adc5-gen3
```

---

### 5. Build the Dell EC module externally

The Dell EC driver can also be built as an external module against the running kernel headers.

Example Makefile:

```make
obj-m := dell-xps-ec.o
```

Build:

```bash
make -C /lib/modules/$(uname -r)/build M="$PWD" modules
```

Verify:

```bash
modinfo ./dell-xps-ec.ko | grep vermagic
```

Install:

```bash
sudo cp dell-xps-ec.ko \
  /lib/modules/$(uname -r)/extra/

sudo depmod -a
```

Load:

```bash
sudo modprobe dell_xps_ec
```

---

### 6. Load automatically at boot

After both modules have been installed under the running kernel module directory and `depmod` has been run, create:

```text
/etc/modules-load.d/dell-ec.conf
```

containing:

```text
qcom-spmi-adc5-gen3
dell-xps-ec
```

For example:

```bash
sudo tee /etc/modules-load.d/dell-ec.conf >/dev/null <<'EOF'
qcom-spmi-adc5-gen3
dell-xps-ec
EOF
```

---

### 7. Verification

Check that both modules are loaded:

```bash
lsmod | grep -E 'qcom_spmi_adc5_gen3|dell_xps_ec'
```

Check the IIO ADC device:

```bash
ls -l /sys/bus/iio/devices/
cat /sys/bus/iio/devices/iio:device0/name
```

Check thermistor values:

```bash
for f in /sys/bus/iio/devices/iio:device0/in_temp*_input; do
        printf '%-25s ' "$f"
        cat "$f"
done
```

Check thermistor labels:

```bash
for f in /sys/bus/iio/devices/iio:device0/in_temp*_label; do
        printf '%-25s ' "$f"
        cat "$f"
done
```

Check EC binding:

```bash
readlink -f /sys/bus/i2c/devices/5-003b/driver
```

Expected:

```text
/sys/bus/i2c/drivers/dell-xps-ec
```

Check kernel log:

```bash
sudo dmesg | grep -Ei \
'dell.xps|temperature reporting|adc5|5-003b'
```

Expected:

```text
dell-xps-ec 5-003b: Started periodic temperature reporting to EC every 100 ms
```

---

### Limitations

This does **not** currently expose direct manual fan-speed control to Linux.

There is currently no standard hwmon interface such as:

```text
fan1_input
fan2_input
pwm1
```

The Dell EC remains responsible for choosing fan speed based on the temperatures supplied by Linux.

As a result, tools such as:

```text
lm-sensors
fancontrol
pwmconfig
Psensor
```

cannot currently display fan RPM or directly control the fans.

Adding fan RPM reporting or manual fan control would require further reverse engineering of the Dell EC I2C protocol and extending `dell-xps-ec`.

