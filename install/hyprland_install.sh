#!/bin/bash

# =============================================================================
# Script d'installation et configuration Hyprland pour ThinkPad T15g
# Configuration: Intel i915 + NVIDIA RTX 3080
# OS: Arch Linux   V1.0
# =============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Vérifications préliminaires
print_header "VÉRIFICATIONS PRÉLIMINAIRES"

# Vérifier si on est sur Arch Linux
if ! command -v pacman &> /dev/null; then
    print_error "Ce script est conçu pour Arch Linux uniquement!"
    exit 1
fi

# Vérifier si on est root
if [[ $EUID -eq 0 ]]; then
    print_error "Ne pas exécuter ce script en tant que root!"
    exit 1
fi

print_success "Système Arch Linux détecté"
print_success "Utilisateur non-root confirmé"


# Sauvegarde et préparation
print_header "SAUVEGARDE ET PRÉPARATION"

# Créer un point de restauration avec timeshift (si disponible)
if command -v timeshift &> /dev/null; then
    print_warning "Création d'un point de restauration recommandée"
    read -p "Voulez-vous créer un point de restauration avec timeshift? (o/N): " create_backup
    if [[ $create_backup =~ ^[Oo]$ ]]; then
        sudo timeshift --create --comments "Avant installation Hyprland" || print_warning "Échec de la création du point de restauration"
    fi
fi

# Mise à jour du système
print_header "MISE À JOUR DU SYSTÈME"
sudo pacman -Syu --noconfirm
print_success "Système mis à jour"

# Installation de yay (AUR helper)
print_header "INSTALLATION DE YAY (AUR HELPER)"

if ! command -v yay &> /dev/null; then
    print_warning "Installation de yay..."
    cd /tmp
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay-bin
    print_success "Yay installé avec succès"
else
    print_success "Yay déjà installé"
fi


# Installation des dépendances Wayland/Hyprland
print_header "INSTALLATION DES DÉPENDANCES WAYLAND"

sudo pacman -S --needed --noconfirm \
    wayland \
    wayland-protocols \
    xorg-xwayland \
    qt5-wayland \
    qt6-wayland \
    polkit-kde-agent \

print_success "Dépendances Wayland installées"

# Installation de PipeWire (audio)
print_header "INSTALLATION ET CONFIGURATION AUDIO (PIPEWIRE)"

# Désinstaller PulseAudio si présent
sudo pacman -Rns --noconfirm pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-equalizer pulseaudio-jack &> /dev/null || true

# Installer PipeWire
sudo pacman -S --needed --noconfirm \
    pipewire \
    wireplumber \
    pipewire-audio \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack sof-firmware \
    pavucontrol bluez bluez-tools blueman 

print_success "PipeWire installé et configuré"

# Installation d'Hyprland et composants essentiels
print_header "INSTALLATION D'HYPRLAND ET COMPOSANTS"

sudo pacman -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    hyprpaper hyprshot satty slurp \
    hyprlock \
    hypridle \
    hyprpicker \
    foot pacman-contrib \
    waybar \
    dunst libnotify \
    fuzzel yazi poppler resvg imagemagick \
    brightnessctl wl-clipboard inxi nvtop \
    inetutils \
    intel-media-driver  libva-intel-driver  vulkan-intel libva

print_success "Hyprland et composants installés"

# Installation de polices
print_header "INSTALLATION DES POLICES"

sudo pacman -S --needed --noconfirm \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    ttf-liberation \
    ttf-dejavu \
    otf-font-awesome \
    ttf-jetbrains-mono \
    ttf-jetbrains-mono-nerd

pacman -S --needed --noconfirm ttf-ms-fonts || print_warning "Échec installation ttf-ms-fonts (optionnel)"

print_success "Polices installées"

# Configuration des répertoires
print_header "CRÉATION DES RÉPERTOIRES DE CONFIGURATION"

mkdir -p ~/.config/hypr/wallpapers
mkdir -p ~/.config/foot
mkdir -p ~/.config/waybar/scripts
mkdir -p ~/.config/dunst
mkdir -p ~/.config/fuzzel
print_success "Répertoires créés"

# Configuration Hyprland
print_header "CONFIGURATION HYPRLAND"

# Configuration principale Hyprland
tee ~/.config/hypr/hyprland.conf > /dev/null << 'EOF'
# Configuration Hyprland pour ThinkPad T15g (Dual GPU: Intel i915 + NVIDIA RTX 3080)
#
# ====== CONFIGURATION MONITEURS ======

monitor=eDP-1,preferred,auto,auto
monitor=desc:ASUSTek COMPUTER INC XG349C M8LMRS028225,prefered,1080x0,auto
monitor=desc:Dell Inc. DELL P2217H RH81R6AR19WS,preferred,0x0,auto,transform,1

$terminal = foot
$fileManager = foot -e yazi
$menu = fuzzel
 
# ====== CONFIGURATION ENVIRONNEMENT ======
env = GTK_THEME,Adwaita:dark

# XDG Desktop Portal
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24

# QT
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
# GTK
env = GDK_SCALE,1

# Mozilla
env = MOZ_ENABLE_WAYLAND,1
env = MOZ_DISABLE_RDD_SANDBOX,1 # Important pour le décodage matériel

# OZONE Applications Electron en wayland
env = OZONE_PLATFORM,wayland
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# For KVM virtual machines
 env = WLR_NO_HARDWARE_CURSORS, 1

# Configuration NVIDIA spécifique
#env = LIBVA_DRIVER_NAME,nvidia
#env = XDG_SESSION_TYPE,wayland
#env = GBM_BACKEND,nvidia-drm
#env = __GLX_VENDOR_LIBRARY_NAME,nvidia

# NVIDIA environment variables
env = NVD_BACKEND,direct
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia

# Configuration multi-GPU (priorité Intel pour économie batterie)
# env = AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0

# Applications Electron/Chromium en Wayland
env = OZONE_PLATFORM,wayland

# ====== PROGRAMMES AU DÉMARRAGE ======

exec-once = waybar
exec-once = dunst
exec-once = hypridle
exec-once = hyprpaper
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

#####################
### LOOK AND FEEL ###
#####################

# Refer to https://wiki.hypr.land/Configuring/Variables/

# https://wiki.hypr.land/Configuring/Variables/#general
general {
    gaps_in = 4
    gaps_out = 8

    border_size = 2

    # https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    # Set to true enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = false

    # Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
    allow_tearing = false

    layout = master
}

# https://wiki.hypr.land/Configuring/Variables/#decoration
decoration {
    rounding = 2
    rounding_power = 2

    # Change transparency of focused and unfocused windows
    active_opacity = 1.0
    inactive_opacity = 1.0

    shadow {
        enabled = false
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
    }

    # https://wiki.hypr.land/Configuring/Variables/#blur
    blur {
        enabled = false
        size = 3
        passes = 1

        vibrancy = 0.1696
    }
}

# https://wiki.hypr.land/Configuring/Variables/#animations
animations {
    enabled = yes, please :)

    # Default animations, see https://wiki.hypr.land/Configuring/Animations/ for more

    bezier = easeOutQuint,0.23,1,0.32,1
    bezier = easeInOutCubic,0.65,0.05,0.36,1
    bezier = linear,0,0,1,1
    bezier = almostLinear,0.5,0.5,0.75,1.0
    bezier = quick,0.15,0,0.1,1

    animation = global, 1, 10, default
    animation = border, 1, 5.39, easeOutQuint
    animation = windows, 1, 4.79, easeOutQuint
    animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
    animation = windowsOut, 1, 1.49, linear, popin 87%
    animation = fadeIn, 1, 1.73, almostLinear
    animation = fadeOut, 1, 1.46, almostLinear
    animation = fade, 1, 3.03, quick
    animation = layers, 1, 3.81, easeOutQuint
    animation = layersIn, 1, 4, easeOutQuint, fade
    animation = layersOut, 1, 1.5, linear, fade
    animation = fadeLayersIn, 1, 1.79, almostLinear
    animation = fadeLayersOut, 1, 1.39, almostLinear
    animation = workspaces, 1, 1.94, almostLinear, fade
    animation = workspacesIn, 1, 1.21, almostLinear, fade
    animation = workspacesOut, 1, 1.94, almostLinear, fade
}


# See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more
dwindle {
    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = true # You probably want this
}

# See https://wiki.hypr.land/Configuring/Master-Layout/ for more
master {
    new_status = master
}

# https://wiki.hypr.land/Configuring/Variables/#misc
misc {
    force_default_wallpaper =  0 # Set to 0 or 1 to disable the anime mascot wallpapers
    disable_hyprland_logo = true # If true disables the random hyprland logo / anime girl background. :(
    vfr = true
}


#############
### INPUT ###
#############

# https://wiki.hypr.land/Configuring/Variables/#input
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 0

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

    touchpad {
        natural_scroll = true
    }
}

# https://wiki.hypr.land/Configuring/Variables/#gestures
gestures {
    workspace_swipe = false
}

# Example per-device config
# See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more
device {
    name = epic-mouse-v1
    sensitivity = -0.5
}


# ====== RÈGLES FENÊTRES ======

# Règles pour applications spécifiques
windowrulev2 = float, class:^(org.pulseaudio.pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, class:^(file_progress)$
windowrulev2 = float, class:^(confirm)$
windowrulev2 = float, class:^(dialog)$
windowrulev2 = float, class:^(download)$
windowrulev2 = float, class:^(notification)$
windowrulev2 = float, class:^(error)$
windowrulev2 = float, class:^(splash)$
windowrulev2 = float, class:^(confirmreset)$

# ====================================== RACCOURCIS CLAVIER ===================================

# Modificateur principal
$mainMod = SUPER

# Applications
bind = $mainMod, RETURN, exec, $terminal
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo # dwindle
bind = $mainMod, J, togglesplit # dwindle

# Navigation focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Navigation workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Déplacer vers workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# sets repeatable binds for resizing the active window
binde= $mainMod SHIFT,right,resizeactive,10 0
binde= $mainMod SHIFT,left,resizeactive,-10 0
binde= $mainMod SHIFT,up,resizeactive,0 -10
binde= $mainMod SHIFT,down,resizeactive,0 10

# Workspaces spéciaux
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Défilement workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Déplacer/redimensionner fenêtres
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Laptop multimedia keys for volume and LCD brightness
bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindel = ,XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+
bindel = ,XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-



# Captures d'écran
bind = , Print, exec, hyprshot -m output
bind = $mainMod, Print, exec, hyprshot -m window
bind = $mainMod SHIFT, Print, exec, hyprshot -m region

# Verrouillage écran
bind = $mainMod, L, exec, hyprlock

# Passthrough SUPER KEY to Virtual Machine
bind = $mainMod SHIFT, P, submap, passthru
submap = passthru
bind = SUPER, Escape, submap, reset
submap = reset
EOF

print_success "Configuration Hyprland créée"

#=================================================== Configuration Waybar==============================
print_header "CONFIGURATION WAYBAR"

tee ~/.config/waybar/config > /dev/null << 'EOF'

// -*- mode: jsonc -*-
{
  "layer": "top",
  "position": "top",
  "spacing": 2,
  
  // Modules de gauche
  "modules-left": [
    "custom/arch",
    "cpu",
    "memory",
    "temperature",
    "power-profiles-daemon",
    "custom/update"
  ],
  
  // Modules du centre
  "modules-center": [
    "hyprland/workspaces"
  ],
  
  // Modules de droite
  "modules-right": [
    "idle_inhibitor",
    "pulseaudio",
    "backlight",
    "network#speed",
    "bluetooth",
    "tray",
    "battery",
    "clock",
    "custom/power"
  ],
  
  // Inclusion de la configuration des modules
  "include": [
    "~/.config/waybar/modules.jsonc"
  ]
}

EOF

tee ~/.config/waybar/modules.jsonc > /dev/null << 'EOF'
{
  // Modules personnalisés
  "custom/arch": {
    "format": "󰣇 ",
    "on-click": "fuzzel",
    "tooltip": true,
    "tooltip-format": "Arch Linux BTW 😎"
  },

  "custom/search": {
    "format": "🔍",
    "on-click": "$HOME/.config/hypr/web-search.sh",
    "tooltip": true,
    "tooltip-format": "Web Search"
  },

  "custom/update": {
    "exec": "~/.config/waybar/scripts/system-update.sh",
    "return-type": "json",
    "format": "{}",
    "on-click": "hyprctl dispatch exec '~/.config/waybar/scripts/system-update.sh up'",
    "interval": 600,
    "min-length": 2,
    "max-length": 2
  },

  "custom/power": {
    "tooltip": true,
    "on-click": "hyprctl dispatch exec '~/.config/waybar/scripts/power-menu.sh'",
    "format": "⏻",
    "tooltip-format": "Power Menu"
  },

  "custom/cava_mviz": {
    "exec": "$HOME/.config/waybar/scripts/WaybarCava.sh",
    "format": "{}",
    "min-length": 12,
    "max-length": 12
  },

  // Modules Hyprland
  "hyprland/workspaces": {
    "disable-scroll": false,
    "all-outputs": true,
    "warp-on-scroll": true,
    "format": "{name}",
    "persistent-workspaces": {
      "1": [],
      "2": [],
      "3": [],
      "4": [],
      "5": []
    }
  },

  "hyprland/window": {
    "format": "{title}",
    "on-click": "hyprctl dispatch fullscreen"
  },

  "hyprland/language": {
    "format": "  {}",
    "format-en": "EN",
    "format-ru": "RU"
  },

  // Modules système
  "cpu": {
    "format": "  {usage}%",
    "tooltip": true,
    "interval": 2,
    "on-click": "foot -e btop"
  },

  "memory": {
    "format": " {}%",
    "tooltip": true,
    "tooltip-format": "RAM: {used:0.1f}G/{total:0.1f}G",
    "on-click": "gnome-disks"
  },

  "temperature": {
    "interval": 10,
    "hwmon-path": "/sys/devices/platform/thinkpad_hwmon/hwmon/hwmon5/temp1_input",
//  "hwmon-path": "/sys/devices/platform/coretemp.0/hwmon/hwmon6/temp1_input",
    "critical-threshold": 80,
     "format-critical": " {temperatureC}",
     "format": " {temperatureC}°C"
  },

  // Audio
  "pulseaudio": {
   "format": "{icon}  {volume}%",
        "format-bluetooth": "{icon} {volume}%  {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": " {volume}%",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
    },
    "on-click": "pavucontrol",
    "scroll-step": 5
  },

  // Réseau
  "network#speed": {
    "interval": 5,
    "format": "{ifname}",
    "format-wifi": "↑ {bandwidthUpBytes} ↓ {bandwidthDownBytes}",
    "format-ethernet": "󰌘 ↑ {bandwidthUpBytes} ↓ {bandwidthDownBytes}",
    "format-disconnected": "󰌙",
    "tooltip": true,
    "tooltip-format-wifi": "Network: {essid}\nSignal: {signaldBm}dBm ({signalStrength}%)\nIP: {ipaddr}/{cidr}",
    "tooltip-format-ethernet": "{ifname} ",
    "tooltip-format-disconnected": " Disconnected",
    "min-length": 24,
    "max-length": 24,
    "on-click": "foot -e  nmtui"
  },

  // Bluetooth
    "bluetooth": {
	"format": "",
	"format-disabled": "󰂳",
	"format-connected": "󰂱 {num_connections}",
	"tooltip-format": " {device_alias}",
	"tooltip-format-connected": "{device_enumerate}",
	"tooltip-format-enumerate-connected": " {device_alias} 󰂄{device_battery_percentage}%",
	"tooltip": true,
	"on-click": "blueberry"
    
    },

  // Batterie
   "battery": {
    "states": {
      "warning": 30,
      "critical": 20
    },
    "format": "{icon} {capacity}%",
    "format-full": "{icon} {capacity}%",
    "format-charging": " {capacity}%",
    "format-plugged": " {capacity}%",
    "format-alt": "{time} {icon}",
    "format-icons": {
      "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
      "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
     },
     "tooltip-format-discharging": "{power:>1.0f}W↓ {capacity}%",
    "tooltip-format-charging": "{power:>1.0f}W↑ {capacity}%",
    "interval": 3,
    "on-click": ""

   },

  // Horloge
  "clock": {
    "format": "{:%H:%M} ",
    "tooltip": false,
    "format-alt": "{:%d-%m-%Y %H:%M:%S}",
    "on-click-right": ""
  },

  // Rétroéclairage
  "backlight": {
    "format": "{icon} {percent}%",
    "format-icons": [" "," "," ","󰃝 ","󰃞 ","󰃟 ","󰃠 "],
    "tooltip-format": "Brightness: {percent}%",
    "on-scroll-up": "brightnessctl s +5%",
    "on-scroll-down": "brightnessctl s 5%-",
    "smooth-scrolling-threshold": 1
  },

  // Profils d'alimentation
  "power-profiles-daemon": {
    "format": "{icon}",
    "tooltip-format": "Power profile: {profile}\nDriver: {driver}",
    "tooltip": true,
    "format-icons": {
     "default": "",
     "performance": "",
     "balanced": "",
     "power-saver": ""
    },
     "on-click": "powerprofilesctl set $(powerprofilesctl get | grep -q performance && echo balanced || echo performance)",
    "on-click-right": "powerprofilesctl set power-saver"
  },

  // Inhibiteur d'inactivité
  "idle_inhibitor": {
    "format": "{icon}",
    "format-icons": {
       "activated": " ",
       "deactivated": " "
    }
  },

  // Plateau système
  "tray": {
    "icon-size": 20,
    "spacing": 4
  },

  // MPRIS
  "mpris": {
    "interval": 10,
    "format": "{player_icon}",
    "format-paused": "{status_icon} <i>{dynamic}</i>",
    "on-click-middle": "playerctl play-pause",
    "on-click": "playerctl previous",
    "on-click-right": "playerctl next",
    "scroll-step": 5.0,
    "on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
    "smooth-scrolling-threshold": 1,
    "player-icons": {
    	"chromium": "",
	"default": "",
	"firefox": "",
	"kdeconnect": "",
	"mopidy": "",
	"mpv": "󰐹",
	"spotify": "",
	"vlc": "󰕼"  
    },
    "status-icons": {
	"paused": "󰐎",
	"playing": "",
	"stopped": ""
    },
        "max-length": 30
  }
}

EOF
##=========================================================================================================
tee ~/.config/waybar/style.css > /dev/null << 'EOF'
@import "mocha.css";

/* Police globale */
* {
  font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
  font-size: 15px;
}

/* Barre principale */
window#waybar {
  background: transparent;
  color: @teal;
  border-radius: 7rem;
  border: 2px solid @teal;
}

window#waybar.empty #window {
  background-color: transparent;
  padding: 0px;
  border: 0px;
}

/* Style général des modules */
#clock,
#battery,
#cpu,
#custom-nvme:hover,
#memory,
#temperature,
#backlight,
#network,
#pulseaudio,
#tray,
#bluetooth,
#idle_inhibitor,
#power-profiles-daemon,
#custom-update,
#mpris {
  background-color: transparent;
  padding: 0 10px;
  border-radius: 7rem;
  transition: all 0.3s ease;
}

/* Effet hover pour tous les modules */
#clock:hover,
#battery:hover,
#cpu:hover,
#custom-nvme:hover,
#memory:hover,
#temperature:hover,
#backlight:hover,
#network:hover,
#pulseaudio:hover,
#tray:hover,
#bluetooth:hover,
#idle_inhibitor:hover,
#power-profiles-daemon:hover,
#custom-update:hover,
#mpris:hover {
  background-color: @maroon;
  color: @base;
}

/* Espaces de travail */
#workspaces {
  border-radius: 7rem;
  background-color: transparent;
}

#workspaces button {
  color: @teal;
  border-radius: 7rem;
  padding: 0 8px;
  transition: all 0.3s ease;
}

#workspaces button.active {
  color: @base;
  background-color: @teal;
}

#workspaces button:hover {
  color: @base;
  background-color: @maroon;
}

#workspaces button.empty {
  opacity: 0.5;
}

/* Modules personnalisés */
#custom-arch {
  margin-left: 5px;
  padding: 0 10px;
  font-size: 25px;
  background-color: transparent;
  border-radius: 7rem;
  transition: all 0.3s ease;
}

#custom-arch:hover {
  background-color: @maroon;
  color: @base;
}

#custom-power {
  margin-right: 5px;
  padding: 0 10px;
  background-color: transparent;
  border-radius: 7rem;
  transition: all 0.3s ease;
}

#custom-power:hover {
  background-color: @maroon;
  color: @base;
}

/* États spéciaux */
#battery.warning {
  background-color: @yellow;
  color: @base;
}

#battery.critical {
  background-color: @red;
  color: @base;
  animation: blink 0.5s linear infinite alternate;
}

#temperature.critical {
  background-color: @red;
  color: @base;
}

/* Animations */
@keyframes blink {
  to {
    opacity: 0.5;
  }
}

/* MPRIS */
#mpris {
  border-radius: 7rem;
  background-color: transparent;
  padding: 0 10px;
}

#mpris:hover {
  background-color: @maroon;
  color: @base;
}

/* Visualiseur audio personnalisé */
#custom-cava_mviz {
  color: @pink;
}

EOF
#===========================================================mocha.css=========================================================
tee ~/.config/waybar/mocha.css > /dev/null << 'EOF'
@define-color rosewater #f5e0dc;
@define-color flamingo #f2cdcd;
@define-color pink #f5c2e7;
@define-color mauve #cba6f7;
@define-color red #f38ba8;
@define-color maroon #eba0ac;
@define-color peach #fab387;
@define-color yellow #f9e2af;
@define-color green #a6e3a1;
@define-color teal #94e2d5;
@define-color sky #89dceb;
@define-color sapphire #74c7ec;
@define-color blue #89b4fa;
@define-color lavender #b4befe;
@define-color text #cdd6f4;
@define-color subtext1 #bac2de;
@define-color subtext0 #a6adc8;
@define-color overlay2 #9399b2;
@define-color overlay1 #7f849c;
@define-color overlay0 #6c7086;
@define-color surface2 #585b70;
@define-color surface1 #45475a;
@define-color surface0 #313244;
@define-color base #1e1e2e;
@define-color mantle #181825;
@define-color crust #11111b;
@define-color brown #561508;

EOF

tee ~/.config/waybar/scripts/system-update.sh > /dev/null << 'EOF'
#!/usr/bin/env bash

# Vérifier si on est sur Arch Linux
if [ ! -f /etc/arch-release ]; then
  exit 0
fi

# Fonction pour vérifier si un paquet est installé
pkg_installed() {
  local pkg=$1
  
  if pacman -Qi "${pkg}" &>/dev/null; then
    return 0
  elif command -v flatpak &>/dev/null && flatpak info "${pkg}" &>/dev/null; then
    return 0
  elif command -v "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Détecter l'assistant AUR
get_aur_helper() {
  if pkg_installed yay; then
    aur_helper="yay"
  elif pkg_installed paru; then
    aur_helper="paru"
  else
    aur_helper=""
  fi
}

get_aur_helper

# Mode mise à jour
if [ "$1" == "up" ]; then
  trap 'pkill -RTMIN+20 waybar' EXIT
  
  command="echo -e '\033[1;36m=== Mise à jour du système ===\033[0m\n'"
  
  # Mises à jour officielles
  command+="sudo pacman -Syu;"
  
  # Mises à jour AUR
  if [ -n "$aur_helper" ]; then
    command+="${aur_helper} -Sua;"
  fi
  
  # Mises à jour Flatpak
  if pkg_installed flatpak; then
    command+="flatpak update;"
  fi
  
  command+="echo -e '\n\033[1;32mMise à jour terminée!\033[0m';"
  command+="read -n 1 -p 'Appuyez sur une touche pour fermer...'"
  
  foot --title " System Update" sh -c "${command}"
  exit 0
fi

# Vérifier les mises à jour AUR
if [ -n "$aur_helper" ]; then
  aur_updates=$(${aur_helper} -Qua 2>/dev/null | wc -l)
else
  aur_updates=0
fi

# Vérifier les mises à jour officielles
official_updates=$(checkupdates 2>/dev/null | wc -l)

# Vérifier les mises à jour Flatpak
if pkg_installed flatpak; then
  flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
else
  flatpak_updates=0
fi

# Total des mises à jour
total_updates=$((official_updates + aur_updates + flatpak_updates))

# Format pour le mode upgrade
if [ "${1}" == "upgrade" ]; then
  printf "Officielles:  %-10s\n" "$official_updates"
  [ -n "$aur_helper" ] && printf "AUR (%s): %-10s\n" "$aur_helper" "$aur_updates"
  [ "$flatpak_updates" -gt 0 ] && printf "Flatpak:     %-10s\n" "$flatpak_updates"
  echo
  exit 0
fi

# Créer le tooltip
tooltip="Officielles: $official_updates"
[ -n "$aur_helper" ] && tooltip+="\nAUR ($aur_helper): $aur_updates"
[ "$flatpak_updates" -gt 0 ] && tooltip+="\nFlatpak: $flatpak_updates"

# Sortie JSON pour Waybar
if [ $total_updates -eq 0 ]; then
  echo "{\"text\":\"\", \"tooltip\":\"Système à jour\"}"
else
  echo "{\"text\":\" \", \"tooltip\":\"${tooltip//\"/\\\"}\"}"
fi

EOF

tee ~/.config/waybar/scripts/power-menu.sh > /dev/null << 'EOF'
#!/bin/bash
# Sauvegardez ce script comme ~/.config/waybar/power-menu.sh
# N'oubliez pas de le rendre exécutable avec : chmod +x ~/.config/waybar/power-menu.sh

choice=$(echo -e "🔐 Verrouiller\n👋 Se déconnecter\n🔄 Redémarrer\n🔴 Éteindre" | fuzzel -d -w 20 -l 4 -p 'Menu système: ' --font="Noto Color Emoji:size=14,Noto Sans:size=12")

case "$choice" in
    "🔐 Verrouiller")
        hyprlock
        ;;
    "👋 Se déconnecter")
        swaymsg exit
        ;;
    "🔄 Redémarrer")
        systemctl reboot
        ;;
    "🔴 Éteindre")
        systemctl poweroff
        ;;
esac

EOF


print_success "Configuration Waybar créée"

#========================== Configuration Hyprpaper (fond d'écran)=====================
print_header "CONFIGURATION FOND D'ÉCRAN"

cp -r ~/data/ma-config/wallpapers ~/.config/hypr/
tee ~/.config/hypr/hyprpaper.conf > /dev/null << 'EOF'

preload = ~/.config/hypr/wallpapers/prefere-arch1.jpg
wallpaper = , ~/.config/hypr/wallpapers/prefere-arch1.jpg
ipc = off
EOF

print_success "Configuration fond d'écran créée"

# ===============================Configuration Hyprlock (verrouillage écran)============
print_header "CONFIGURATION VERROUILLAGE ÉCRAN"

tee ~/.config/hypr/hyprlock.conf > /dev/null << 'EOF'
general {
    grace = 2
    no_fade_in = false
}

background {
    monitor =
    path = ~/.config/hypr/wallpapers/prefere-arch1.jpg
    blur_passes = 2
    blur_size = 8
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
}

input-field {
    monitor =
    size = 600, 100
    position = 0, 0
    halign = center
    valign = center
    
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = false
    dots_rounding = -1
    
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = false
    fade_timeout = 100
    
    placeholder_text = <i>Input Password...</i>
    hide_input = false
    rounding = -1
    
    check_color = rgb(204, 136, 34)
    fail_color = rgb(204, 34, 34)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    fail_timeout = 2000
    fail_transition = 300
    
    capslock_color = -1
    numlock_color = -1
    bothlock_color = -1
    
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$TIME"
    color = rgba(200, 200, 200, 1.0)
    font_size = 55
    font_family = JetBrains Mono Nerd Font
    
    position = -200, 10
    halign = right
    valign = bottom
    shadow_passes = 5
    shadow_size = 10
}

label {
    monitor =
    text = $USER
    color = rgba(200, 200, 200, 1.0)
    font_size = 30
    font_family = JetBrains Mono Nerd Font
    
    position = -200, 260
    halign = right
    valign = bottom
    shadow_passes = 5
    shadow_size = 10
}
auth {
    fingerprint:enabled = true
}
EOF

print_success "Configuration verrouillage écran créée"

#==============================foot.ini================================================

tee ~/.config/foot/foot.ini > /dev/null << 'EOF'

font=monospace:size=12

[colors]

background=000000

EOF

print_success "Configuration foot créée"

#================================fuzzel.ini============================================

tee ~/.config/fuzzel/fuzzel.ini > /dev/null << 'EOF'

# output=<not set>
# font=monospace
# dpi-aware=auto
# use-bold=no
# prompt="> "
# placeholder=
# icon-theme=hicolor
# icons-enabled=yes
# hide-before-typing=no
# fields=filename,name,generic
# password-character=*
# filter-desktop=no
# match-mode=fzf
# sort-result=yes
# match-counter=no
# delayed-filter-ms=300
# delayed-filter-limit=20000
# show-actions=no
# terminal=$TERMINAL -e  # Note: you cannot actually use environment variables here
# launch-prefix=<not set>
# list-executables-in-path=no

# anchor=center
# x-margin=0
# y-margin=0
# lines=15
# width=30
# tabs=8
# horizontal-pad=40
# vertical-pad=8
# inner-pad=0

# image-size-ratio=0.5

# line-height=<use font metrics>
# letter-spacing=0

# layer=overlay
# keyboard-focus=on-demand
# exit-on-keyboard-focus-loss=yes

# cache=<not set>

# render-workers=<number of logical CPUs>
# match-workers=<number of logical CPUs>

[colors]
 background=2e3440ff
 text=657b83ff
 prompt=586e75ff
 placeholder=93a1a1ff
 input=657b83ff
 match=cb4b16ff
 selection=eee8d5ff
 selection-text=586e75ff
 selection-match=cb4b16ff
 counter=93a1a1ff
 border=eee8d5ff

[border]
 width=1
 radius=10

[dmenu]

[key-bindings]
# cancel=Escape Control+g Control+c Control+bracketleft
# execute=Return KP_Enter Control+y
# execute-or-next=Tab
# execute-input=Shift+Return Shift+KP_Enter
# cursor-left=Left Control+b
# cursor-left-word=Control+Left Mod1+b
# cursor-right=Right Control+f
# cursor-right-word=Control+Right Mod1+f
# cursor-home=Home Control+a
# cursor-end=End Control+e
# delete-prev=BackSpace Control+h
# delete-prev-word=Mod1+BackSpace Control+BackSpace Control+w
# delete-line-backward=Control+u
# delete-next=Delete KP_Delete Control+d
# delete-next-word=Mod1+d Control+Delete Control+KP_Delete
# delete-line-forward=Control+k
# prev=Up Control+p
# prev-with-wrap=ISO_Left_Tab
# prev-page=Page_Up KP_Page_Up
# next=Down Control+n
# next-with-wrap=none
# next-page=Page_Down KP_Page_Down
# expunge=Shift+Delete
# clipboard-paste=Control+v XF86Paste
# primary-paste=Shift+Insert Shift+KP_Insert

# custom-N: *dmenu mode only*. Like execute, but with a non-zero
# exit-code; custom-1 exits with code 10, custom-2 with 11, custom-3
# with 12, and so on.

# custom-1=Mod1+1
# custom-2=Mod1+2
# custom-3=Mod1+3
# custom-4=Mod1+4
# custom-5=Mod1+5
# custom-6=Mod1+6
# custom-7=Mod1+7
# custom-8=Mod1+8
# custom-9=Mod1+9
# custom-10=Mod1+0
# custom-11=Mod1+exclam
# custom-12=Mod1+at
# custom-13=Mod1+numbersign
# custom-14=Mod1+dollar
# custom-15=Mod1+percent
# custom-16=Mod1+dead_circumflex
# custom-17=Mod1+ampersand
# custom-18=Mod1+asterix
# custom-19=Mod1+parentleft


EOF

print_success "Configuration fuzzel créée"
#================================hypridle.conf==========================================

tee ~/.config/hypr/hypridle.conf > /dev/null << 'EOF'
general {
    lock_cmd = pidof hyprlock || hyprlock       # avoid starting multiple hyprlock instances.
    before_sleep_cmd = loginctl lock-session    # lock before suspend.
    after_sleep_cmd = hyprctl dispatch dpms on  # to avoid having to press a key twice to turn on the display.
}

listener {
    timeout = 120                                # 2 min.
    on-timeout = brightnessctl -s set 10         # set monitor backlight to minimum, avoid 0 on OLED monitor.
    on-resume = brightnessctl -r                 # monitor backlight restore.
}

# turn off keyboard backlight, comment out this section if you dont have a keyboard backlight.
listener {
    timeout = 30                                          # 30 Sec.
    on-timeout = brightnessctl -sd tpacpi::kbd_backlight set 0 # turn off keyboard backlight.
    on-resume  = brightnessctl -rd tpacpi::kbd_backlight        # turn on keyboard backlight.
}

listener {
    timeout = 300                                 # 5min
    on-timeout = loginctl lock-session            # lock screen when timeout has passed
}

listener {
    timeout = 330                                 # 5.5min
    on-timeout = hyprctl dispatch dpms off        # screen off when timeout has passed
    on-resume = hyprctl dispatch dpms on          # screen on when activity is detected after timeout has fired.
}

#listener {
#    timeout = 1800                                # 30min
#    on-timeout = systemctl suspend                # suspend pc
#}
EOF

print_success "Configuration hypridle.conf créée"

#=============================================== Configuration des services====================================
print_header "CONFIGURATION DES SERVICES SYSTÈME"

sudo systemctl enable bluetooth.service
#==================================== chmod +x tout les scripts =============================

chmod +x ~/.config/waybar/scripts/*

# Installation gestionnaire de connexion (optionnel)
print_header "GESTIONNAIRE DE CONNEXION (OPTIONNEL)"

read -p "Voulez-vous installer Ly comme gestionnaire de connexion? (o/N): " install_ly
if [[ $install_ly =~ ^[Oo]$ ]]; then
    sudo pacman -S --needed --noconfirm ly
    sudo systemctl enable ly.service
    print_success "Ly installé et activé"
else
    print_warning "Vous devrez lancer Hyprland manuellement depuis TTY avec: Hyprland"
fi

# Script de démarrage pour TTY
print_header "SCRIPT DE DÉMARRAGE TTY"

tee ~/.bash_profile > /dev/null << 'EOF'
# Auto-démarrage Hyprland sur tty1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec Hyprland
fi
EOF

print_success "Script de démarrage TTY créé"

# Instructions finales
print_header "INSTALLATION TERMINÉE"

print_success "Installation d'Hyprland terminée avec succès!"
echo ""
echo -e "${YELLOW}ÉTAPES SUIVANTES:${NC}"
echo "1. Redémarrez votre système: sudo reboot"
echo "2. Après redémarrage:"
if [[ $install_ly =~ ^[Oo]$ ]]; then
    echo "   - Ly se lancera automatiquement"
    echo "   - Sélectionnez 'Hyprland' dans le menu de session"
else
    echo "   - Connectez-vous en TTY (Ctrl+Alt+F1)"
    echo "   - Tapez votre nom d'utilisateur et mot de passe"
    echo "   - Hyprland se lancera automatiquement"
fi
echo ""
echo -e "${YELLOW}RACCOURCIS IMPORTANTS:${NC}"
echo "- SUPER + T: Terminal (Foot)"
echo "- SUPER + R: Menu applications (fuzzel)"
echo "- SUPER + E: Gestionnaire de fichiers (yazi)"
echo "- SUPER + Q: Fermer fenêtre"
echo "- SUPER + L: Verrouiller écran"
echo "- SUPER + M: Quitter Hyprland"
echo ""
echo -e "${YELLOW}DÉPANNAGE:${NC}"
echo "- Fichiers de configuration: ~/.config/hypr/"
echo "- Logs Hyprland: ~/.cache/hyprland/hyprland.log"
echo "- En cas de problème, consultez: https://wiki.hypr.land"
echo ""
echo -e "${GREEN}Configuration optimisée pour votre ThinkPad T15g (Intel i915 + NVIDIA RTX 3080)${NC}"
echo -e "${GREEN}Dual GPU configuré avec priorité Intel pour économie batterie${NC}"
