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
> EC thermal management on the Dell Latitude 5455 remains experimental. This implementation is based on the Dell XPS 13 9345 EC driver and Val Packett's Dell Thena device-tree work.
>
> Incorrect thermistor readings or EC communication failures could affect fan behavior. Keep a known-working kernel and DTB available for recovery.
>
> **Tested configuration:** Dell Latitude 5455 (Snapdragon X Plus X1P-64-100), kernel `7.2.9-jg-0-qcom-x1e`.

### Overview

The Dell Latitude 5455 uses an Embedded Controller (EC) to manage platform thermal behavior and fan speeds.

Under Linux, the implementation works as follows:

1. The Qualcomm PMIC ADC reads the board thermistors.
2. The `dell-xps-ec` driver retrieves those temperatures through the Linux Industrial I/O (IIO) subsystem.
3. Every 100 ms, the driver forwards the temperature readings to the Dell EC over I²C.
4. The EC firmware determines fan behavior according to its internal thermal policy.

Linux does **not** directly control fan speed or PWM through this implementation.

Three components are required:

- An EC-enabled Device Tree Blob (DTB).
- The Qualcomm ADC5 Gen3 driver (`qcom-spmi-adc5-gen3`).
- The Dell EC driver (`dell-xps-ec`).

Both drivers are already present in the newer jglathe kernel source tree, but they may be disabled in the distributed kernel configuration.

### 1. EC-enabled device tree

Two DTS variants are provided in this repository:

| File | Description |
|---|---|
| [`x1p64100-dell-latitude-5455.dts`](x1p64100-dell-latitude-5455.dts) | Standard variant, without experimental EC support |
| [`x1p64100-dell-latitude-5455-ec.dts`](x1p64100-dell-latitude-5455-ec.dts) | Experimental variant with EC thermal and fan management |

The EC-enabled version preserves the existing Latitude 5455 configuration while adding the EC device, thermistor ADC channels, and associated GPIO definitions.

These EC additions are intended to be temporary until equivalent support is integrated into the appropriate upstream Dell device-tree files.

#### Origin of the EC configuration

The implementation is based on [Val Packett's Dell Thena EC commit](https://github.com/valpackett/linux-qclaptops/commit/28a7eb40940c1d9f61be221e4f5832c8705bcca7):

`arm64: dts: qcom: x1-dell-thena: add EC`

The relevant hardware configuration is:

| Component | Configuration |
|---|---|
| EC I²C bus | `i2c5` |
| EC address | `0x3b` |
| EC interrupt | GPIO66 |
| Interrupt trigger | Level low |
| EC reset | GPIO65 (reserved) |
| Thermistor ADC | `pmk8550_adc_tm` |

These GPIO assignments were also verified against the live device tree on the Latitude 5455 running the previous working configuration.

The EC node uses:

```dts
compatible = "dell,xps13-9345-ec";
```

This allows the existing Dell XPS EC driver to bind to the Latitude's embedded controller.

**No new GPIO assignments or pin functions were introduced for the kernel 7.2.9 migration.**

#### Thermistor channels

The original EC implementation supports seven thermistor inputs.

Testing on the Latitude 5455 with kernel `7.2.9-jg-0-qcom-x1e` produced the following results:

| Channel | Observed behavior | EC forwarding |
|---|---|---|
| `sys_therm0` | Plausible, changing temperature | Yes |
| `sys_therm1` | Plausible, changing temperature | Yes |
| `sys_therm2` | Plausible, changing temperature | Yes |
| `sys_therm3` | Plausible, changing temperature | Yes |
| `sys_therm4` | Plausible, changing temperature | Yes |
| `sys_therm5` | Plausible, changing temperature | Yes |
| `sys_therm6` | Constant −40.960°C | No |

An important difference from kernel 7.2.0 is that `sys_therm0` now produces plausible readings.

Previously, this channel was stuck at 130.048°C. With the new ADC5 Gen3 setup, it reports temperatures around 39–40°C and changes smoothly over time.

This suggests that the old extreme reading was associated with the previous ADC configuration or implementation, rather than establishing that the thermistor is physically absent.

`sys_therm6` still returns the constant value −40.960°C and is excluded from EC temperature reporting.

#### EC temperature mapping

The EC-enabled DTS exposes six thermistor channels to the EC driver:

```dts
io-channel-names =
    "sys_therm0",
    "sys_therm1",
    "sys_therm2",
    "sys_therm3",
    "sys_therm4",
    "sys_therm5";
```

The corresponding EC commands are:

| Thermistor | EC command |
|---|---|
| `sys_therm0` | `0x02` |
| `sys_therm1` | `0x03` |
| `sys_therm2` | `0x04` |
| `sys_therm3` | `0x05` |
| `sys_therm4` | `0x06` |
| `sys_therm5` | `0x07` |

All seven channels remain defined in the ADC portion of the DTS for monitoring and diagnostics, but only six are referenced by the EC node.

The existing `dell-xps-ec.c` driver can therefore be used **without modifying its thermistor reporting table**.

The driver attempts to acquire each thermistor by name. If a channel is absent from the EC's `io-channels`, that channel is skipped during periodic reporting.

The original seven-entry EC thermistor initialization profile remains unchanged.

### 2. Build the EC-enabled DTB

Clone the [jglathe kernel repository](https://github.com/jglathe/linux_ms_dev_kit) and select the kernel revision corresponding to your installed kernel.

For the tested version:

```bash
git clone https://github.com/jglathe/linux_ms_dev_kit.git
cd linux_ms_dev_kit

git fetch origin --tags

git switch -c latitude-5455-7.2.9 \
    refs/tags/jg/ubuntu-qcom-x1e-7.2.9-jg-0
```

If this local branch already exists, simply switch to it.

Install the required build dependencies:

```bash
sudo apt install \
    build-essential \
    flex bison \
    device-tree-compiler \
    libssl-dev libelf-dev
```

Configure the kernel build:

```bash
make ARCH=arm64 ubuntu_x1e_defconfig
```

Back up the existing Latitude DTS before replacing it:

```bash
cp arch/arm64/boot/dts/qcom/x1p64100-dell-latitude-5455.dts \
   /tmp/x1p64100-dell-latitude-5455-original.dts
```

Then copy the experimental DTS from this repository into the kernel source tree:

```bash
cp /path/to/DELL-Latitude-5455-Ubuntu/x1p64100-dell-latitude-5455-ec.dts \
   arch/arm64/boot/dts/qcom/x1p64100-dell-latitude-5455.dts
```

Build the DTB:

```bash
make ARCH=arm64 -j"$(nproc)" \
    qcom/x1p64100-dell-latitude-5455.dtb
```

Alternatively:

```bash
make ARCH=arm64 -j"$(nproc)" dtbs
```

The compiled device tree will be located at:

```text
arch/arm64/boot/dts/qcom/x1p64100-dell-latitude-5455.dtb
```

Install the DTB using your existing bootloader configuration, ensuring the intended kernel boots with the matching device tree.

**Do not overwrite your only working DTB.** Retain a recovery boot option using the previous kernel and device tree.

### 3. Check the kernel driver configuration

The relevant configuration options are:

```text
CONFIG_QCOM_SPMI_ADC5_GEN3
CONFIG_EC_DELL_XPS
```

Check your installed kernel:

```bash
KVER=$(uname -r)

grep -E \
'CONFIG_(QCOM_SPMI_ADC5_GEN3|EC_DELL_XPS)' \
"/boot/config-$KVER"
```

Both drivers can be built into the kernel (`=y`) or compiled as modules (`=m`).

However, the precompiled `7.2.9-jg-0-qcom-x1e` packages tested here contained:

```text
# CONFIG_QCOM_SPMI_ADC5_GEN3 is not set
# CONFIG_EC_DELL_XPS is not set
```

Although the driver source files are included in the kernel repository, the distributed kernel does not necessarily include the compiled modules.

In that situation, both drivers can be compiled externally **without rebuilding the complete kernel**.

If your kernel already includes the drivers, skip the external compilation steps below.

### 4. Build the missing drivers as external modules

The following procedure was tested with `7.2.9-jg-0-qcom-x1e`.

First, ensure the matching kernel headers are installed:

```bash
KVER=$(uname -r)

ls -ld "/lib/modules/$KVER/build"
```

The build directory must correspond to the exact running kernel version.

The following dependencies should also be available:

```bash
grep -E \
'^CONFIG_(IIO|SPMI|THERMAL|QCOM_VADC_COMMON|AUXILIARY_BUS|REGMAP_SPMI)=' \
"/boot/config-$KVER"
```

For the tested kernel:

```text
CONFIG_IIO=y
CONFIG_SPMI=y
CONFIG_THERMAL=y
CONFIG_QCOM_VADC_COMMON=m
CONFIG_AUXILIARY_BUS=y
CONFIG_REGMAP_SPMI=y
```

#### Prepare the external build directory

Assuming the jglathe kernel repository is already cloned:

```bash
KVER=$(uname -r)

SRC="/path/to/linux_ms_dev_kit"
BUILD="$HOME/latitude-ec-modules-$KVER"

mkdir -p "$BUILD/include/linux/iio/adc"
```

Copy the driver source files from the matching kernel revision:

```bash
cp "$SRC/drivers/platform/arm64/dell-xps-ec.c" \
   "$BUILD/"

cp "$SRC/drivers/iio/adc/qcom-spmi-adc5-gen3.c" \
   "$BUILD/"

cp "$SRC/include/linux/iio/adc/qcom-adc5-gen3-common.h" \
   "$BUILD/include/linux/iio/adc/"
```

Create a `Makefile`:

```bash
cat > "$BUILD/Makefile" <<'EOF'
obj-m += dell-xps-ec.o
obj-m += qcom-spmi-adc5-gen3.o

ccflags-y += -I$(src)/include
EOF
```

#### Compile

```bash
cd "$BUILD"

make -C "/lib/modules/$KVER/build" \
    M="$PWD" \
    -j"$(nproc)" \
    modules
```

If successful, the directory should contain:

```text
dell-xps-ec.ko
qcom-spmi-adc5-gen3.ko
```

Verify the module versions:

```bash
modinfo ./dell-xps-ec.ko | grep vermagic
modinfo ./qcom-spmi-adc5-gen3.ko | grep vermagic
```

The modules must be compatible with the running kernel.

#### Install

```bash
sudo install -Dm644 qcom-spmi-adc5-gen3.ko \
    "/lib/modules/$KVER/extra/qcom-spmi-adc5-gen3.ko"

sudo install -Dm644 dell-xps-ec.ko \
    "/lib/modules/$KVER/extra/dell-xps-ec.ko"

sudo depmod -a "$KVER"
```

Load the ADC driver first, followed by the EC driver:

```bash
sudo modprobe qcom-spmi-adc5-gen3
sudo modprobe dell-xps-ec
```

These are external modules built from the kernel's existing source files. No changes to GPIO configuration or the kernel image are necessary.

> **Note:** Out-of-tree modules may produce kernel taint and module-signature warnings. If the kernel rejects unsigned modules, appropriate module signing may be required. Do not disable security protections merely to bypass module loading errors.

### 5. Load automatically at boot

Once both modules have been tested successfully, they can be loaded automatically using:

```text
/etc/modules-load.d/dell-ec.conf
```

Create the file:

```bash
sudo tee /etc/modules-load.d/dell-ec.conf >/dev/null <<'EOF'
qcom-spmi-adc5-gen3
dell-xps-ec
EOF
```

The two modules are installed under the kernel-specific module directory, so they need to be rebuilt or provided by the kernel packages when upgrading to a new kernel version.

The configuration file can remain unchanged between kernel updates.

### 6. Verify EC operation

#### Verify both drivers are loaded

```bash
lsmod | grep -E \
    'qcom_spmi_adc5_gen3|dell_xps_ec'
```

For the tested setup, both modules appear in `lsmod`, along with the supporting `qcom_vadc_common` module.

#### Verify EC initialization

```bash
sudo journalctl -k -b --no-pager |
    grep -Ei 'dell.xps|5-003b|adc5|thermistor'
```

A successful initialization should contain:

```text
dell-xps-ec 5-003b: Started periodic temperature reporting to EC every 100 ms
```

With the six-thermistor configuration, the following warning is expected:

```text
dell-xps-ec 5-003b: Thermistor sys_therm6 not available: -19
```

This occurs because `sys_therm6` is intentionally absent from the EC's input list.

A successful probe confirms that the temperature-reporting worker was started. It does not independently confirm every subsequent I²C transfer or the EC's fan decisions.

#### Verify EC driver binding

```bash
if [ -L /sys/bus/i2c/devices/5-003b/driver ]; then
    readlink -f /sys/bus/i2c/devices/5-003b/driver
else
    echo "EC driver not bound"
fi
```

Expected output:

```text
/sys/bus/i2c/drivers/dell-xps-ec
```

The I²C bus number may differ on other kernel configurations.

#### Check the thermistor temperatures

Locate the IIO ADC device and read all labeled thermistors:

```bash
for d in /sys/bus/iio/devices/iio:device*; do
    [ -r "$d/name" ] || continue

    echo "Device: $(cat "$d/name")"

    for f in "$d"/in_temp*_label; do
        [ -r "$f" ] || continue

        label=$(cat "$f")
        [[ "$label" == sys_therm* ]] || continue

        input="${f%_label}_input"
        value=$(cat "$input" 2>/dev/null) || continue

        printf '%-14s %8.3f°C\n' \
            "$label" \
            "$(awk -v v="$value" 'BEGIN {print v/1000}')"
    done
done
```

On the tested kernel, an example set of readings was:

```text
sys_therm0     39.234°C
sys_therm1     38.540°C
sys_therm2     39.553°C
sys_therm3     36.980°C
sys_therm4     36.962°C
sys_therm5     41.050°C
sys_therm6    -40.960°C
```

The first six channels showed plausible, varying temperatures. The last channel remained fixed at an implausible value.

These temperatures are examples, not expected fixed values.

#### Check for ADC or EC communication errors

```bash
sudo journalctl -k -b --no-pager |
    grep -Ei \
    'Failed to (read|send)|ADC.*timed out|conversion fault|dell.xps'
```

Repeated ADC read failures, conversion timeouts, or failed EC I²C transmissions require investigation.

#### Check the EC interrupt

The EC uses GPIO66. Its Linux IRQ number can vary between boots.

```bash
grep '5-003b' /proc/interrupts
```

The interrupt is configured as level-low. Its presence confirms IRQ registration, but the interrupt count alone does not indicate correct fan behavior.

### 7. Suspend/resume and fan behavior

The Dell EC driver includes suspend and resume handling.

On suspend, it sends an EC command and stops periodic temperature reporting. On resume, it sends the corresponding resume command and restarts temperature reporting.

After enabling EC support, verify that:

- The display, keyboard, and trackpad recover correctly after suspend.
- The system continues reading valid thermistor temperatures.
- The fans behave normally during idle, moderate load, and subsequent cooling.
- The kernel log does not show repeated ADC or I²C communication failures.

Avoid sustained heavy workloads until EC initialization and temperature reporting have been verified.

### 8. Limitations and known issues

#### Fan RPM and direct fan control

The current driver does not expose standard hardware-monitoring attributes such as:

```text
fan1_input
fan2_input
pwm1
```

Consequently, tools such as `lm-sensors`, `fancontrol`, `pwmconfig`, and Psensor cannot directly read fan RPM or control fan speed using this implementation.

The EC firmware continues to manage the fans.

Reading actual fan speeds or controlling them from Linux would require further reverse engineering of the Dell EC protocol.

#### Occasional maximum-fan behavior

During testing, the fans have occasionally increased unexpectedly to maximum speed.

The cause has not yet been established. Possible explanations include EC firmware policy, invalid or missing thermal information, and communication or event-handling issues.

The newer ADC5 Gen3 setup resolves the previously implausible `sys_therm0` measurement, but this has not yet been proven to resolve the fan behavior.

#### Incomplete EC event handling

The existing `dell-xps-ec` IRQ handler acknowledges the Linux interrupt without fully decoding the EC event.

This is an area of the driver that may need further development.

#### Experimental thermal profile

The EC driver still uses the original Dell XPS thermistor initialization profile.

Although six thermistors now return plausible temperatures on the Latitude 5455, the exact EC firmware thermal policy and its handling of unavailable sensors have not been fully characterized.

### 9. Future upstream integration

The separate `x1p64100-dell-latitude-5455-ec.dts` is intended as an interim solution.

Ideally, the required Dell EC configuration will eventually be added to the appropriate shared Dell Thena device-tree files or the Latitude-specific DTS upstream, with the necessary driver support enabled in distributed kernels.

Once this happens, the experimental DTS and external module build instructions can be retired.

Until then, the standard and EC-enabled DTS variants are kept separate to allow users to opt into experimental fan management without modifying the default configuration.

**References:**

- [jglathe/linux_ms_dev_kit](https://github.com/jglathe/linux_ms_dev_kit)
- [Val Packett's Dell Thena EC device-tree commit](https://github.com/valpackett/linux-qclaptops/commit/28a7eb40940c1d9f61be221e4f5832c8705bcca7)
- [Dell XPS EC driver source](https://github.com/jglathe/linux_ms_dev_kit/blob/jg/ubuntu-qcom-x1e-7.2.9-jg-0/drivers/platform/arm64/dell-xps-ec.c)
- [Qualcomm ADC5 Gen3 driver source](https://github.com/jglathe/linux_ms_dev_kit/blob/jg/ubuntu-qcom-x1e-7.2.9-jg-0/drivers/iio/adc/qcom-spmi-adc5-gen3.c)

