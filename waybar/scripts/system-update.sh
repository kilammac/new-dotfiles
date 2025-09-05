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

# Sortie JSON pour Waybar 
if [ $total_updates -eq 0 ]; then
  echo "{\"text\":\"\", \"tooltip\":\"Système à jour\"}"
else
  echo "{\"text\":\"\", \"tooltip\":\"${tooltip//\"/\\\"}\"}"
fi

