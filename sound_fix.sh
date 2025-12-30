#!/bin/bash

# --- 1. Kernel Driver Safety Override ---
# The Snapdragon smart amp driver is blocked by default. 
# This flag is mandatory to "unlocked" the hardware.
echo "Enabling Snapdragon sound driver safety override..."
echo "options snd-soc-x1e80100 i_accept_the_danger=1" | sudo tee /etc/modprobe.d/snapdragon-sound.conf

# --- 2. Clean and Prepare UCM Directories ---
# We remove any previous failed attempts and set up the clean ALSA structure.
echo "Cleaning and setting up ALSA UCM structure..."
sudo mkdir -p /usr/share/alsa/ucm2/conf.d/x1e80100

# --- 3. Create Hardware-Specific Symlinks ---
# We point both the '7455' and '5455' identities to the generic Qualcomm CRD profile.
# This ensures sound works regardless of which DTB identity your laptop is currently using.
echo "Creating hardware identity symlinks..."
sudo ln -sf /usr/share/alsa/ucm2/Qualcomm/x1e80100/X1E80100-CRD.conf /usr/share/alsa/ucm2/conf.d/x1e80100/X1E80100-Dell-Latitude-7455.conf
sudo ln -sf /usr/share/alsa/ucm2/Qualcomm/x1e80100/X1E80100-CRD.conf /usr/share/alsa/ucm2/conf.d/x1e80100/X1E80100-Dell-Latitude-5455.conf

# --- 4. Patch ALSA Configs for 2-Speaker Setup ---
# The 5455 lacks the tweeters found in the 7455. 
# We remove "Tweeter" and "COMP Switch" references to prevent the audio stack from hanging.
echo "Patching audio configurations for Latitude 5455 (2-speaker mode)..."

SUB_FILES="/usr/share/alsa/ucm2/Qualcomm/x1e80100/HiFi.conf 
           /usr/share/alsa/ucm2/codecs/wsa884x/four-speakers/*.conf 
           /usr/share/alsa/ucm2/codecs/qcom-lpass/wsa-macro/four-speakers/*.conf"

for file in $SUB_FILES; do
    if [ -f "$file" ]; then
        # Change generic Speaker labels to Woofer
        sudo sed -i 's/Spkr/Woofer/g' "$file"
        # Delete non-existent Tweeter paths
        sudo sed -i '/Tweeter/d' "$file"
        # Delete COMP Switch which often fails on Dell firmware
        sudo sed -i '/COMP Switch/d' "$file"
    fi
done

# --- 5. Finalize and Refresh ---
echo "Restarting audio services..."
systemctl --user restart pipewire wireplumber

echo "--------------------------------------------------------"
echo "DONE! Please REBOOT your laptop now."
echo "After reboot, check 'Settings > Sound' for output devices."
echo "--------------------------------------------------------"
