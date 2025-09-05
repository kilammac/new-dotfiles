## Prérequis système (Arch Linux)

```bash
# Mise à jour complète
sudo pacman -Syu

# Dépendances essentielles
sudo pacman -S base-devel git curl wget unzip xz jdk17-openjdk
```

## 1. Installation Flutter (méthode officielle)

```bash
# Créer le dossier de développement
mkdir -p ~/development
cd ~/development

# Cloner Flutter
git clone https://github.com/flutter/flutter.git -b stable

# Variables d'environnement permanentes
echo '# Flutter' >> ~/.bashrc
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
echo 'export CHROME_EXECUTABLE="/usr/bin/chromium"' >> ~/.bashrc
source ~/.bashrc

# Vérification initiale
flutter --version
```

## 2. Installation des Android Command Line Tools (SANS Android Studio)

```bash
# Créer la structure Android
mkdir -p ~/Android/cmdline-tools
cd ~/Android/cmdline-tools

# Télécharger les Command Line Tools (dernière version)
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip

# Structurer correctement (IMPORTANT pour le SDK Manager)
mv cmdline-tools latest

# Variables d'environnement Android
echo '# Android SDK' >> ~/.bashrc
echo 'export ANDROID_HOME=$HOME/Android' >> ~/.bashrc
echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.bashrc
source ~/.bashrc
```

## 3. Installation des composants Android requis

```bash
# Accepter les licences (OBLIGATOIRE)
sdkmanager --licenses

# Installer les composants essentiels
sdkmanager "platform-tools"
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
sdkmanager "system-images;android-34;google_apis;x86_64"
sdkmanager "emulator"

# Vérifier les installations
sdkmanager --list_installed
```

## 4. Création d'un émulateur Android (AVD)

```bash
# Créer un AVD (Android Virtual Device)
avdmanager create avd \
    -n "Pixel_6_API_34" \
    -k "system-images;android-34;google_apis;x86_64" \
    -d "pixel_6"

# Lister les AVDs créés
avdmanager list avd

# Configuration optionnelle de l'AVD
echo "hw.keyboard=yes" >> ~/.android/avd/Pixel_6_API_34.avd/config.ini
echo "hw.gpu.enabled=yes" >> ~/.android/avd/Pixel_6_API_34.avd/config.ini
```

## 1. Configuration du smartphone Android

### Sur votre smartphone :

1. **Activer les options développeur** :
   - Aller dans `Paramètres` → `À propos du téléphone`
   - Taper 7 fois sur `Numéro de build` jusqu'à voir "Vous êtes maintenant développeur"

2. **Activer le débogage USB** :
   - Aller dans `Paramètres` → `Options pour les développeurs`
   - Activer `Débogage USB`
   - Activer `Installation via USB` (si disponible)
   - Activer `Rester éveillé` (optionnel, pratique pour le dev)

## 2. Installation des pilotes USB (Arch Linux)

```bash
# Installer les règles udev pour Android
sudo pacman -S android-udev

# Ajouter votre utilisateur au groupe adbusers
sudo usermod -aG adbusers $USER

# Redémarrer la session ou recharger les groupes
newgrp adbusers

# Redémarrer les services udev
sudo systemctl restart systemd-udevd
```

## 3. Connexion et test

```bash
# Connecter votre smartphone via USB

# Vérifier la détection
lsusb | grep -i android  # ou grep avec la marque de votre téléphone

# Tester ADB
adb devices

# Si "unauthorized", accepter sur le téléphone la fenêtre qui apparaît
# Puis retester
adb devices
```

**Résultat attendu :**

```
List of devices attached
1A2B3C4D5E6F    device
```
