#!/bin/bash

echo "Starting Hyprland and DMS setup..."


# 1. Update system
sudo pacman -Syu --noconfirm

# 2. Install Hyprland, Ghostty, and basic tools
# Added audio (pipewire + firmware), polkit, fprintd, i2c-tools, and accountsservice
sudo pacman -S --noconfirm \
    hyprland ghostty foot waybar wofi mako swaybg brightnessctl playerctl wl-clipboard \
    qt6-multimedia qt6-wayland fastfetch dgop power-profiles-daemon \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    sof-firmware alsa-firmware alsa-utils \
    polkit accountsservice fprintd i2c-tools hypridle hyprlock wayland-protocols \
    
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    ttf-liberation \
    ttf-dejavu \
    otf-font-awesome \
    ttf-jetbrains-mono \
    ttf-jetbrains-mono-nerd

# Enable power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon.service

# Setup I2C for monitor brightness control
sudo usermod -aG i2c $USER

# 3. Install AUR helper (yay)
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

# 4. Install DMS, Greeter and optional dependencies
echo "Installing Dank Material Shell, DMS Greeter, and dependencies..."
# Dependencies as requested: Quickshell, cava, cliphist, dgop, dsearch, matugen, qt6-multimedia, khal
# Note: dms-shell-bin usually pulls quickshell. greetd-dms-greeter-bin is the correct package name for the greeter on AUR.
# Removed dgop-bin in favor of pacman dgop. Added khal.
yay -S --noconfirm dms-shell-bin greetd-dms-greeter-git cava cliphist dsearch-bin matugen-bin khal

# Enable dsearch user service
systemctl --user enable --now dsearch

# 5. Enable DMS Greeter (via greetd)
echo "Configuring greetd to use dms-greeter..."
sudo systemctl enable greetd
# We need to ensure greetd is configured to use dms-greeter.
# Usually this involves editing /etc/greetd/config.toml
if [ -f /etc/greetd/config.toml ]; then
    sudo sed -i 's/^command = .*/command = "dms-greeter --command hyprland"/' /etc/greetd/config.toml
else
    sudo mkdir -p /etc/greetd
    cat <<EOF | sudo tee /etc/greetd/config.toml
[default_session]
command = "dms-greeter --command hyprland"
user = "greeter"
EOF
fi

# 6. Basic Hyprland config for DMS
echo "Configuring Hyprland shortcuts..."
mkdir -p ~/.config/hypr
if [ ! -f ~/.config/hypr/hyprland.conf ]; then
    cat <<EOF > ~/.config/hypr/hyprland.conf
# Hyprland Config for DMS
exec-once = dms run

# Shortcuts
bind = SUPER, RETURN, exec, ghostty
bind = SUPER, Q, killactive, 

# Monitor setup (Adjust as needed)
monitor=,preferred,auto,1
EOF
else
    # Update existing shortcuts if they exist
    # Fix SUPER Q to killactive instead of exit
    sed -i 's/bind = SUPER, Q, exit/bind = SUPER, Q, killactive/' ~/.config/hypr/hyprland.conf
    # Also fix it if it was mapped to something else or just ensure it's correct?
    # The previous script had: sed -i 's/bind = SUPER, Q, exec, kitty/bind = SUPER, RETURN, exec, ghostty/'
    # We'll keep that but also ensure Q is killactive
    
    # Ensure DMS autostart is set
    if ! grep -q "dms run" ~/.config/hypr/hyprland.conf; then
        echo "exec-once = dms run" >> ~/.config/hypr/hyprland.conf
    fi
fi

# 7. Note: DMS can also be managed via systemd user service if preferred:
# systemctl --user enable --now dms

echo "Hyprland and DMS setup complete! Please log out and back in."
