#!/usr/bin/env bash
set -euo pipefail

DOWNLOAD_DIR="${HOME}/Downloads"
REPO="https://github.com/sidouxp3/dotfile_hyperland.git"
REPO_DIR="${HOME}/dotfile_hyperland"

_installPackages() {
  sudo pacman -S --noconfirm --needed "$@"
}

_installPackagesAUR() {
  if command -v yay &>/dev/null; then
    yay -S --noconfirm --needed "$@"
  else
    echo "yay n'est pas installé, impossible d'installer les paquets AUR"
    return 1
  fi
}

_configureDotfiles() {
  if [[ -d "$REPO_DIR" ]]; then
    cp -rv "$@" "$HOME/.config"
  else
    echo "Répertoire des dotfiles introuvable: $REPO_DIR"
    return 1
  fi
}

# Vérification et chargement des fichiers de configuration
if [[ -f "./core/packages.sh" ]]; then
  source "./core/packages.sh"
else
  echo "Fichier packages.sh introuvable, certaines fonctionnalités seront désactivées"
fi

if [[ -f "./core/configuration.sh" ]]; then
  source "./core/configuration.sh"
else
  echo "Fichier configuration.sh introuvable, certaines fonctionnalités seront désactivées"
fi

echo "============================================="
echo "-----| GENERATE HOME DIR |-----"
echo "============================================="
if ! command -v xdg-user-dirs-update &>/dev/null; then
  _installPackages "xdg-user-dirs"
fi
xdg-user-dirs-update

echo "============================================="
echo "-----| INSTALL AUR HELPER (yay) |-----"
echo "============================================="
if ! command -v yay &>/dev/null; then
  mkdir -p "$DOWNLOAD_DIR"
  cd "$DOWNLOAD_DIR" || exit 1
  if ! git clone https://aur.archlinux.org/yay.git; then
    echo "Échec du clonage de yay"
    exit 1
  fi
  cd yay || exit 1
  if ! makepkg -si; then
    echo "Échec de l'installation de yay"
    exit 1
  fi
else
  echo "yay est déjà installé"
fi

echo "============================================="
echo "-----| INSTALL GENERAL PACKAGES |-----"
echo "============================================="
if [[ -n "${general[*]}" ]]; then
  _installPackages "${general[@]}"
else
  echo "Aucun paquet général à installer"
fi

echo "============================================="
echo "-----| INSTALL AUDIO PACKAGES |-----"
echo "============================================="
if [[ -n "${audio[*]}" ]]; then
  _installPackages "${audio[@]}"
else
  echo "Aucun paquet audio à installer"
fi

echo "============================================="
echo "-----| INSTALL WINDOW MANAGER PACKAGES |-----"
echo "============================================="
if [[ -n "${window_manager[*]}" ]]; then
  _installPackages "${window_manager[@]}"
else
  echo "Aucun paquet de window manager à installer"
fi

echo "============================================="
echo "-----| INSTALL NVIDIA (optionnel) |-----"
echo "============================================="
if [[ -f "./nvidia.sh" ]]; then
  if ! ./nvidia.sh; then
    echo "Échec de l'installation NVIDIA (non critique)"
  fi
else
  echo "Script nvidia.sh introuvable, ignoré"
fi

echo "============================================="
echo "-----| INSTALL AUR PACKAGES |-----"
echo "============================================="
if [[ -n "${aur[*]}" ]]; then
  if ! _installPackagesAUR "${aur[@]}"; then
    echo "Certains paquets AUR n'ont pas pu être installés"
  fi
else
  echo "Aucun paquet AUR à installer"
fi

echo "============================================="
echo "-----| CLONING DOTFILES |-----"
echo "============================================="
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1
if [[ ! -d "$REPO_DIR" ]]; then
  if ! git clone "$REPO"; then
    echo "Échec du clonage des dotfiles"
    exit 1
  fi
fi
cd "$REPO_DIR" || exit 1

echo "============================================="
echo "-----| CONFIGURE DOTFILES |-----"
echo "============================================="
if [[ -n "${folders[*]}" ]]; then
  if ! _configureDotfiles "${folders[@]}"; then
    echo "Échec de la configuration des dotfiles"
  fi
else
  echo "Aucun dossier de configuration à copier"
fi

echo "============================================="
echo "-----| CONFIGURE DOCKER |-----"
echo "============================================="
if groups "$USER" | grep -q '\bdocker\b'; then
  echo "L'utilisateur fait déjà partie du groupe docker"
else
  sudo usermod -aG docker "$USER"
  echo "Ajouté au groupe docker. Un redémarrage peut être nécessaire."
fi

echo "============================================="
echo "-----| INSTALLING SNAP |-----"
echo "============================================="
if ! command -v snap &>/dev/null; then
  cd "$DOWNLOAD_DIR" || exit 1
  if ! git clone https://aur.archlinux.org/snapd.git; then
    echo "Échec du clonage de snapd"
  else
    cd snapd || exit 1
    if ! makepkg -si; then
      echo "Échec de l'installation de snapd"
    else
      sudo systemctl enable --now snapd.socket
      sudo systemctl enable --now snapd.apparmor.service
      sudo ln -s /var/lib/snapd/snap /snap
    fi
  fi
else
  echo "snap est déjà installé"
fi

echo "============================================="
echo "-----| CHANGE SHELL TO FISH |-----"
echo "============================================="
if command -v fish &>/dev/null; then
  if [[ "$SHELL" != "$(command -v fish)" ]]; then
    sudo chsh -s "$(command -v fish)" "$USER" || chsh -s "$(command -v fish)"
  else
    echo "Fish est déjà le shell par défaut"
  fi
else
  echo "Fish n'est pas installé, impossible de le définir comme shell par défaut"
fi

mkdir -p "$HOME/.local/bin"
touch "$HOME/.local/bin/env.fish" 2>/dev/null || true

echo "============================================="
echo "-----| INSTALLING FISHER |-----"
echo "============================================="
if command -v fish &>/dev/null; then
  if ! fish -c 'command -v fisher' &>/dev/null; then
    fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher' || \
      echo "Échec de l'installation de fisher"
  fi
  fish -c 'fisher install jethrokuan/tide' || echo "Échec de l'installation de tide"
  fish -c 'tide configure' || echo "Échec de la configuration de tide"
else
  echo "Fish n'est pas installé, impossible d'installer fisher"
fi

echo "============================================="
echo "-----| CONFIGURE TMUX |-----"
echo "============================================="
rm -rf "$HOME/.tmux"
if ! git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
  echo "Échec de l'installation de tpm"
fi

echo "============================================="
echo "-----| CONFIGURE FONTS |-----"
echo "============================================="
if [[ -d "$REPO_DIR/Fonts_used" ]]; then
  mkdir -p ~/.fonts
  cp -r "$REPO_DIR/Fonts_used" ~/.fonts
  if [[ -f "$HOME/.config/fontconfig/fonts.conf" ]]; then
    sudo cp "$HOME/.config/fontconfig/fonts.conf" /etc/fonts/local.conf
    sudo fc-cache -fv
    fc-cache -fv
  else
    echo "Fichier de configuration des polices introuvable"
  fi
else
  echo "Répertoire des polices introuvable"
fi

echo "============================================="
echo "-----| CONFIGURE THEMES |-----"
echo "============================================="
cd "$REPO_DIR" || exit 1
mkdir -p ~/.themes
if [[ -d "Juno-ocean" ]]; then
  sudo cp -r Juno-ocean /usr/share/themes/
fi
if [[ -d "kora" ]]; then
  sudo cp -r kora /usr/share/icons/
fi

cd "$DOWNLOAD_DIR" || exit 1
if [[ ! -d "Graphite-gtk-theme" ]]; then
  if git clone https://github.com/vinceliuice/Graphite-gtk-theme.git; then
    cd Graphite-gtk-theme || exit 1
    ./install.sh -d ~/.themes -t teal -c dark -s standard -l --tweaks black rimless normal || \
      echo "Échec de l'installation du thème Graphite"
  else
    echo "Échec du clonage du thème Graphite"
  fi
else
  echo "Thème Graphite déjà présent"
fi

echo "============================================="
echo "-----| INSTALL WALLPAPERS |-----"
echo "============================================="
if [[ -d "$REPO_DIR/Wallpaper" ]]; then
  mkdir -p ~/Pictures/wallpaper/
  cp -r "$REPO_DIR/Wallpaper/"* ~/Pictures/wallpaper/
else
  echo "Répertoire des fond d'écran introuvable"
fi

echo "============================================="
echo "-----| INSTALL SNAP PACKAGES |-----"
echo "============================================="
if command -v snap &>/dev/null; then
  if ! command -v subl &>/dev/null; then
    sudo snap install sublime-text --classic || echo "Échec de l'installation de sublime-text"
  fi
  if ! command -v onlyoffice-desktopeditors &>/dev/null; then
    sudo snap install onlyoffice-desktopeditors || echo "Échec de l'installation de onlyoffice"
  fi
else
  echo "snap n'est pas installé, impossible d'installer les paquets snap"
fi

echo "============================================="
echo "-----| CONFIGURE HARDWARE ACCELERATION |-----"
echo "============================================="
sudo tee /etc/environment >/dev/null <<'EOF'
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
MOZ_DISABLE_RDD_SANDBOX=1
EOF

echo "============================================="
echo "-----| CONFIGURE MX MASTER |-----"
echo "============================================="
if groups "$USER" | grep -q '\binput\b'; then
  echo "L'utilisateur fait déjà partie du groupe input"
else
  sudo usermod -a -G input "$USER"
fi
echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' | \
  sudo tee /etc/udev/rules.d/99-solaar.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "============================================="
echo "-----| CONFIGURE APP ARMOR |-----"
echo "============================================="
if systemctl is-active --quiet apparmor 2>/dev/null; then
  echo "AppArmor est déjà activé"
else
  sudo systemctl enable --now apparmor || echo "Échec de l'activation d'AppArmor"
fi

echo "============================================="
echo "-----| CONFIGURE FIREWALL |-----"
echo "============================================="
if command -v ufw &>/dev/null; then
  sudo systemctl enable --now ufw
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 22/tcp
  sudo ufw --force enable
else
  echo "ufw n'est pas installé, impossible de configurer le pare-feu"
fi

echo "============================================="
echo "-----| INSTALLATION TERMINÉE |-----"
echo "Un redémarrage est recommandé pour appliquer toutes les modifications"
echo "============================================="
