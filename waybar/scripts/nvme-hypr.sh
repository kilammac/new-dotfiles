#!/bin/bash

# Script de montage/démontage NVMe pour Hyprland avec intégration Waybar et notifications
# Usage: ./nvme-hypr.sh [mount|umount|status|toggle|waybar]

# Configuration - Modifiez selon vos besoins
DEFAULT_UUID="bd5636d4-3da6-41ea-a863-fbefa9229dda"
DEFAULT_LABEL="MALEK"
MOUNT_POINT="/mnt/nvme-data"
MOUNT_OPTIONS="defaults,noatime,user"
USE_POLKIT=false
# Configuration des notifications
NOTIFY_ENABLED=true
NOTIFY_TIMEOUT=3000  # en millisecondes
NOTIFY_ICON_MOUNT="📤"
NOTIFY_ICON_UMOUNT=" "
NOTIFY_ICON_ERROR="❌"
NOTIFY_ICON_WARNING="⚠️"

# Configuration Waybar
WAYBAR_SIGNAL=8  # Signal SIGUSR1 + 8 pour custom/nvme
WAYBAR_CONFIG_FILE="$HOME/.config/waybar/modules/nvme.json"

# Couleurs pour les notifications et waybar
COLOR_MOUNTED="#50fa7b"    # Vert
COLOR_UNMOUNTED="#6272a4"  # Gris
COLOR_ERROR="#ff5555"      # Rouge
COLOR_WARNING="#f1fa8c"    # Jaune

# Fonction de notification
notify() {
    local title="$1"
    local message="$2"
    local icon="$3"
    local urgency="${4:-normal}"
    local timeout="${5:-$NOTIFY_TIMEOUT}"
    
    if [[ "$NOTIFY_ENABLED" == "true" ]]; then
        if command -v dunstify >/dev/null 2>&1; then
            dunstify -a "NVMe Manager" \
                     -i "$icon" \
                     -t "$timeout" \
                     -u "$urgency" \
                     "$title" "$message"
        elif command -v notify-send >/dev/null 2>&1; then
            notify-send -a "NVMe Manager" \
                       -i "$icon" \
                       -t "$timeout" \
                       -u "$urgency" \
                       "$title" "$message"
        else
            echo "[$icon] $title: $message"
        fi
    fi
}

# Fonction pour mettre à jour Waybar
update_waybar() {
    if command -v pkill >/dev/null 2>&1; then
        pkill -RTMIN+$WAYBAR_SIGNAL waybar 2>/dev/null || true
    fi
}

# Fonction pour créer la configuration Waybar
create_waybar_config() {
    local config_dir=$(dirname "$WAYBAR_CONFIG_FILE")
    mkdir -p "$config_dir"
    
    cat > "$WAYBAR_CONFIG_FILE" << 'EOF'
{
    "custom/nvme": {
        "format": "{}",
        "exec": "~/.local/bin/nvme-hypr.sh waybar",
        "on-click": "~/.local/bin/nvme-hypr.sh toggle",
        "on-click-right": "~/.local/bin/nvme-hypr.sh status",
        "interval": "once",
        "signal": 8,
        "tooltip": true,
        "tooltip-format": "Clic gauche: monter/démonter\nClic droit: statut détaillé"
    }
}
EOF
    
    echo "Configuration Waybar créée: $WAYBAR_CONFIG_FILE"
}

# Fonction pour obtenir le statut JSON pour Waybar
waybar_output() {
    local status_info
    local tooltip
    local class="unmounted"
    
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        # Monté
        local mounted_device=$(findmnt -n -o SOURCE "$MOUNT_POINT" 2>/dev/null || echo "Inconnu")
        local disk_usage=$(df -h "$MOUNT_POINT" 2>/dev/null | awk 'NR==2 {print $3"/"$2" ("$5")"} END {if(NR==0) print "N/A"}')
        
        status_info=" 📤 NVMe"
        tooltip="🟢 Monté sur: $MOUNT_POINT\\n📀 Périphérique: $mounted_device\\n📊 Usage: $disk_usage"
        class="mounted"
    else
        # Non monté
        status_info="  NVMe"
        tooltip="🔴 Non monté\\n📁 Point de montage: $MOUNT_POINT"
        class="unmounted"
    fi
    
    # Échapper les guillemets et caractères spéciaux pour JSON
    status_info=$(echo "$status_info" | sed 's/"/\\"/g')
    tooltip=$(echo "$tooltip" | sed 's/"/\\"/g')
    
    # Sortie JSON valide pour Waybar
    #printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$status_info" "$tooltip" "$class" 
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$status_info" "$tooltip" "$class"
}

# Fonction pour trouver le périphérique
find_device() {
    local identifier="$1"
    local device=""
    
    if [[ -z "$identifier" ]]; then
        if [[ -n "$DEFAULT_UUID" && "$DEFAULT_UUID" != "VOTRE_UUID_ICI" ]]; then
            identifier="UUID=$DEFAULT_UUID"
        elif [[ -n "$DEFAULT_LABEL" && "$DEFAULT_LABEL" != "VOTRE_LABEL_ICI" ]]; then
            identifier="LABEL=$DEFAULT_LABEL"
        else
            notify "Configuration manquante" "Aucun UUID/Label configuré" "$NOTIFY_ICON_ERROR" "critical"
            return 1
        fi
    fi
    
    if [[ "$identifier" =~ ^UUID= ]]; then
        local uuid="${identifier#UUID=}"
        device=$(blkid -U "$uuid" 2>/dev/null)
    elif [[ "$identifier" =~ ^LABEL= ]]; then
        local label="${identifier#LABEL=}"
        device=$(blkid -L "$label" 2>/dev/null)
    else
        device=$(blkid -U "$identifier" 2>/dev/null)
        if [[ -z "$device" ]]; then
            device=$(blkid -L "$identifier" 2>/dev/null)
        fi
    fi
    
    if [[ -z "$device" ]]; then
        notify "Périphérique introuvable" "Impossible de localiser le disque NVMe" "$NOTIFY_ICON_ERROR" "critical"
        return 1
    fi
    
    echo "$device"
    return 0
}

# Fonction pour monter avec interface graphique
mount_disk_gui() {
    local identifier="$1"
    local device
    
    # Afficher notification de début
    notify "Montage en cours..." "Recherche du disque NVMe..." "$NOTIFY_ICON_MOUNT" "low" 2000
    
    device=$(find_device "$identifier")
    if [[ $? -ne 0 ]]; then
        update_waybar
        return 1
    fi
    
    # Vérifier si déjà monté
    if mountpoint -q "$MOUNT_POINT"; then
        notify "Déjà monté" "Le disque NVMe est déjà monté sur $MOUNT_POINT" "$NOTIFY_ICON_WARNING" "normal"
        update_waybar
        return 0
    fi
    
    # Créer le point de montage
    if [[ ! -d "$MOUNT_POINT" ]]; then
        sudo mkdir -p "$MOUNT_POINT" || {
            notify "Erreur de création" "Impossible de créer $MOUNT_POINT" "$NOTIFY_ICON_ERROR" "critical"
            update_waybar
            return 1
        }
    fi
    
    # Monter
    if pkexec mount -o "$MOUNT_OPTIONS" "$device" "$MOUNT_POINT"; then
        local size=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $2}')
        local available=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $4}')
        
        notify "✅ Montage réussi" \
               "NVMe monté sur $MOUNT_POINT\nTaille: $size | Libre: $available" \
               "$NOTIFY_ICON_MOUNT" "normal"
        
        # Optionnel: ouvrir le gestionnaire de fichiers
        if command -v thunar >/dev/null 2>&1; then
            thunar "$MOUNT_POINT" &
        elif command -v nautilus >/dev/null 2>&1; then
            nautilus "$MOUNT_POINT" &
        elif command -v dolphin >/dev/null 2>&1; then
            dolphin "$MOUNT_POINT" &
        fi
    else
        notify "❌ Échec du montage" "Impossible de monter le disque NVMe" "$NOTIFY_ICON_ERROR" "critical"
        update_waybar
        return 1
    fi
    
    update_waybar
    return 0
}

# Fonction pour démonter avec interface graphique
umount_disk_gui() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        notify "Pas monté" "Le disque NVMe n'est pas monté" "$NOTIFY_ICON_WARNING" "normal"
        update_waybar
        return 0
    fi
    
    # Vérifier les processus utilisant le disque
    local processes=$(lsof +D "$MOUNT_POINT" 2>/dev/null | tail -n +2)
    if [[ -n "$processes" ]]; then
        local process_count=$(echo "$processes" | wc -l)
        
        # Notification avec choix
        notify "⚠️ Processus actifs" \
               "$process_count processus utilisent le disque\nUtilisez 'nvme-hypr.sh umount-force' pour forcer" \
               "$NOTIFY_ICON_WARNING" "normal" 5000
        
        # Optionnel: afficher les processus dans un terminal
        if command -v alacritty >/dev/null 2>&1; then
            alacritty -e bash -c "echo 'Processus utilisant $MOUNT_POINT:'; lsof +D '$MOUNT_POINT'; echo ''; echo 'Appuyez sur Entrée pour fermer...'; read" &
        elif command -v kitty >/dev/null 2>&1; then
            kitty -e bash -c "echo 'Processus utilisant $MOUNT_POINT:'; lsof +D '$MOUNT_POINT'; echo ''; echo 'Appuyez sur Entrée pour fermer...'; read" &
        fi
        
        update_waybar
        return 1
    fi
    
    # Démontage
    notify "Démontage en cours..." "Démontage du disque NVMe..." "$NOTIFY_ICON_UMOUNT" "low" 2000
    
    if pkexec umount "$MOUNT_POINT"; then
        notify "✅ Démontage réussi" "Disque NVMe démonté avec succès" "$NOTIFY_ICON_UMOUNT" "normal"
    else
        notify "❌ Échec du démontage" "Impossible de démonter le disque NVMe" "$NOTIFY_ICON_ERROR" "critical"
        update_waybar
        return 1
    fi
    
    update_waybar
    return 0
}

# Fonction de démontage forcé
umount_force_gui() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        notify "Pas monté" "Le disque NVMe n'est pas monté" "$NOTIFY_ICON_WARNING" "normal"
        update_waybar
        return 0
    fi
    
    notify "⚠️ Démontage forcé" "Fermeture des processus et démontage..." "$NOTIFY_ICON_WARNING" "normal" 3000
    
    # Tuer les processus en douceur d'abord
    local pids=$(lsof +D "$MOUNT_POINT" 2>/dev/null | tail -n +2 | awk '{print $2}' | sort -u)
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs -r kill -TERM 2>/dev/null
        sleep 2
        echo "$pids" | xargs -r kill -KILL 2>/dev/null
    fi
    
    # Démontage forcé
    if pkexec umount -f "$MOUNT_POINT" 2>/dev/null || pkexec umount -l "$MOUNT_POINT" 2>/dev/null; then
        notify "✅ Démontage forcé réussi" "Disque NVMe démonté (forcé)" "$NOTIFY_ICON_UMOUNT" "normal"
    else
        notify "❌ Démontage impossible" "Impossible de démonter même en mode forcé" "$NOTIFY_ICON_ERROR" "critical"
        update_waybar
        return 1
    fi
    
    update_waybar
    return 0
}

# Fonction toggle (monter si démonté, démonter si monté)
toggle_mount() {
    if mountpoint -q "$MOUNT_POINT"; then
        umount_disk_gui
    else
        mount_disk_gui
    fi
}

# Fonction de statut détaillé avec notification
status_detailed() {
    local status_msg=""
    local icon=""
    local urgency="normal"
    
    if mountpoint -q "$MOUNT_POINT"; then
        local mounted_device=$(findmnt -n -o SOURCE "$MOUNT_POINT" 2>/dev/null)
        local disk_info=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $2" total, "$3" utilisé, "$4" libre ("$5" plein)"}')
        
        status_msg="🟢 NVMe Monté\n━━━━━━━━━━━━━━━━\n📍 Point: $MOUNT_POINT\n💽 Device: $mounted_device\n📊 Espace: $disk_info"
        icon="$NOTIFY_ICON_MOUNT"
    else
        status_msg="🔴 NVMe Non Monté\n━━━━━━━━━━━━━━━━━━━━\n📍 Point: $MOUNT_POINT\n💽 Prêt à monter"
        icon="$NOTIFY_ICON_UMOUNT"
    fi
    
    notify "Statut NVMe" "$status_msg" "$icon" "$urgency" 8000
}

# Fonction d'installation
install() {
    echo "Installation du script NVMe pour Hyprland..."
    
    # Copier le script dans ~/.local/bin
    local install_dir="$HOME/.local/bin"
    local install_path="$install_dir/nvme-hypr.sh"
    
    mkdir -p "$install_dir"
    cp "$0" "$install_path"
    chmod +x "$install_path"
    
    echo "✅ Script installé: $install_path"
    
    # Créer la configuration Waybar
    create_waybar_config
    echo "✅ Configuration Waybar créée"
    
    # Instructions pour Waybar
    echo ""
    echo "📋 Pour intégrer à Waybar, ajoutez ceci à votre configuration:"
    echo ""
    echo "Dans ~/.config/waybar/config:"
    echo '  "modules-right": [..., "custom/nvme"],'
    echo ""
    echo "Dans ~/.config/waybar/style.css:"
    cat << 'EOF'
#custom-nvme {
    background-color: @base;
    color: @text;
    border-radius: 10px;
    padding: 0 15px;
    margin: 3px 0;
}

#custom-nvme.mounted {
    color: #50fa7b;
}

#custom-nvme.unmounted {
    color: #6272a4;
}
EOF
    echo ""
    echo "🔧 Rechargez Waybar: killall waybar && waybar &"
}

# Fonction d'aide
show_help() {
    cat << EOF
🔧 NVMe Manager pour Hyprland

Usage:
  $0 mount              - Monte le disque NVMe
  $0 umount             - Démonte le disque NVMe  
  $0 umount-force       - Démonte en forçant (tue les processus)
  $0 toggle             - Monte si démonté, démonte si monté
  $0 status             - Affiche le statut détaillé
  $0 waybar             - Sortie JSON pour Waybar
  $0 install            - Installe le script et configure Waybar
  
Intégration Hyprland:
  - Utilisez dans Waybar pour contrôle graphique
  - Notifications via Dunst/notify-send
  - Raccourcis clavier possibles

Exemples de raccourcis pour ~/.config/hypr/hyprland.conf:
  bind = SUPER, F9, exec, nvme-hypr.sh toggle
  bind = SUPER SHIFT, F9, exec, nvme-hypr.sh status
EOF
}

# Script principal
main() {
    case "$1" in
        mount)
            mount_disk_gui "$2"
            ;;
        umount|unmount)
            umount_disk_gui
            ;;
        umount-force|unmount-force)
            umount_force_gui
            ;;
        toggle)
            toggle_mount
            ;;
        status)
            status_detailed
            ;;
        waybar)
            waybar_output
            ;;
        install)
            install
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            if [[ -n "$1" ]]; then
                notify "Commande inconnue" "Commande '$1' non reconnue" "$NOTIFY_ICON_ERROR" "normal"
            fi
            show_help
            exit 1
            ;;
    esac
}

# Vérification de l'environnement Hyprland
if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" && "$1" != "install" && "$1" != "help" ]]; then
    echo "⚠️  Ce script est optimisé pour Hyprland"
    echo "Continuer quand même ? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

main "$@"
