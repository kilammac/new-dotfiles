#!/bin/bash



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
