#!/bin/bash

# Check if the script is run as root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Associative array to store set names and explanations
declare -A sets
sets["development"]="This set includes Notepadqq, PyCharm Community Edition, R and Wireshark."
sets["games"]="This set includes open source games, Heroic Launcher for Epic/GOG/Amazon games, and Steam."
sets["matroska"]="This set includes video editing utilities for multiple formats including Matroska"
sets["virt"]="This set includes VirtualBox"
sets["k3b"]="This set includes K3b and CD/DVD burning utilities"

# Function to add repositories
add_repositories() {
  echo "Adding repositories..."
  echo "Adding Brave Browser repository..."
  curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg  | apt-key add -
  echo -e "#Brave Browser\ndeb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list
  echo "Adding Firefox (Debian Package) Repository"
  add-apt-repository -y ppa:mozillateam/ppa
  echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
  echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" > /etc/apt/preferences.d/mozillateamppa
  echo "Adding GIMP PPA"
  add-apt-repository -y ppa:ubuntuhandbook1/gimp
  echo "Adding Git PPA"
  add-apt-repository -y ppa:git-core/ppa
  echo "Adding Kubuntu Backports PPA"
  add-apt-repository -y ppa:kubuntu-ppa/backports
  add-apt-repository -y ppa:kubuntu-ppa/backports-extra
  echo "Adding LibreOffice PPA"
  add-apt-repository -y ppa:libreoffice/libreoffice-still
  echo "Adding Microsoft VSCode and Edge repositories..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  echo "Adding PyCharm Community repository..."
  curl -s https://s3.eu-central-1.amazonaws.com/jetbrains-ppa/0xA6E8698A.pub.asc | gpg --dearmor | tee /usr/share/keyrings/jetbrains-ppa-archive-keyring.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/jetbrains-ppa-archive-keyring.gpg] http://jetbrains-ppa.s3-website.eu-central-1.amazonaws.com any main" | tee /etc/apt/sources.list.d/jetbrains-ppa.list > /dev/null
  echo "Adding Signal repository..."
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | tee /etc/apt/sources.list.d/signal-xenial.list
  rm -f signal-desktop-keyring.gpg
  echo "Adding Telegram PPA"
  add-apt-repository -y ppa:atareao/telegram
  echo "Adding VirtualBox repository..."
  wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc |  gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
  echo -e "#Oracle VirtualBox\ndeb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian jammy contrib" > /etc/apt/sources.list.d/oracle-virtualbox.list
  echo "Adding Flathub..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  apt update
  apt full-upgrade -y
}

# Function to install a set of packages
install_packages() {
  local set_name="$1"
  local packages=()

  case "$set_name" in
    "development")
      packages=(code libclang-dev libcrypto++-dev libssl-dev libxml2-dev notepadqq okteta pycharm-community r-base wireshark wireshark-common wireshark-doc wireshark-gtk)
      ;;
    "games")
      packages=(aisleriot astromenace chromium-bsu frozen-bubble lgc-pg lgogdownloader opentyrian scummvm scummvm-data scummvm-tools steam supertux supertuxkart supertuxkart-data)
      ;;
    "matroska")
      packages=(handbrake mediainfo-gui mkvtoolnix-gui)
      ;;
    "virt")
      packages=(virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso virtualbox-guest-utils-hwe virtualbox-guest-x11-hwe virtualbox-qt)
      ;;
    "k3b")
      packages=(burner-cdrkit cdrskin dvd+rw-tools gstreamer1.0-plugins-bad libsox-fmt-all k3b kde-config-cddb normalize-audio sox tracker vcdimager xorriso)
      ;;
    *)
      echo "Invalid set name. Exiting."
      exit 1
      ;;
  esac

  # Install the selected set of packages
  echo "Installing $set_name packages..."
  apt install --install-recommends -y "${packages[@]}"

  # Check if the installation was successful
  if [ $? -eq 0 ]; then
    echo "$set_name installation successful."

    # Run additional commands after set installation (if needed)
    if [ "$set_name" == "games" ]; then
      echo "Completing game packages setup..."
      wget https://raw.githubusercontent.com/carolvs-mccallen/testground/main/tyrian-data_68_all.deb
      wget https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.9.2/heroic_2.9.2_amd64.deb
      wget https://github.com/lutris/lutris/releases/download/v0.5.14/lutris_0.5.14_all.deb
      dpkg -i *.deb
      apt install -f -y
      rm *.deb
    elif [ "$set_name" == "virt" ]; then
      echo "Completing virtualization packages setup..."
      usermod -aG vboxusers $USER
    elif [ "$set_name" == "development" ]; then
      echo "Completing development packages setup..."
      snap install kommit
    elif [ "$set_name" == "k3b" ]; then
      echo "Completing K3b packages setup..."
      usermod -aG cdrom $USER
    fi
  else
    echo "$set_name installation failed."
  fi
}

# Function to install Flatpak apps
install_flatpak_apps() {
  read -p "Do you want to install Flatpak and Snap apps? (Y/N): " choice
  case "$choice" in
    [Yy]*)
      echo "Installing Flatpak apps..."
      flatpak install flathub -y org.gtk.Gtk3theme.Breeze com.plexamp.Plexamp tv.plex.PlexDesktop io.github.JaGoLi.ytdl_gui
      echo "Applying automatic theme selection for Flatpak apps"
      flatpak override --filesystem=xdg-config/gtk-3.0:ro
      flatpak update
      echo "Installing Snap apps..."
      snap remove --purge firefox
      snap refresh
      snap install bitwarden discord red-app spotify whatsapp-for-linux
      ;;
    [Nn]*)
      echo "No Flatpak apps will be installed."
      ;;
    *)
      echo "Invalid choice. No Flatpak apps will be installed."
      ;;
  esac
}

# Running pre-requisite upgrade
echo "Running initial Kubuntu updates..."
apt update
apt-get install --install-recommends -y curl flatpak exfatprogs libncurses5 libncurses5:i386 make make-doc malcontent-gui neofetch plasma-discover-backend-flatpak
apt full-upgrade -y

# Add repositories and run commands before package selection
add_repositories

# Initial installation
echo "Updating package repository and installing initial packages..."
wget https://github.com/jgraph/drawio-desktop/releases/download/v22.0.2/drawio-amd64-22.0.2.deb
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
wget https://mega.nz/linux/repo/xUbuntu_22.04/amd64/megasync-xUbuntu_22.04_amd64.deb
wget https://mega.nz/linux/repo/xUbuntu_22.04/amd64/nemo-megasync-xUbuntu_22.04_amd64.deb
wget https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_117.0.2045.55-1_amd64.deb
wget https://github.com/popcorn-official/popcorn-desktop/releases/download/v0.4.9/Popcorn-Time-0.4.9-amd64.deb
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
wget https://zoom.us/client/5.16.2.8828/zoom_amd64.deb
dpkg -i *.deb
apt install -f -y
rm *.deb
apt install --install-recommends -y alien arj brave-browser cifs-utils digikam dolphin-nextcloud falkon firefox firefox-locale-en firefox-locale-es fonts-lyx frei0r-plugins gimp gimp-data gimp-data-extras gimp-help-common gimp-help-en gimp-help-es hashdeep hunspell-en-au hunspell-en-ca hunspell-en-gb hunspell-en-za hunspell-es hyphen-en-ca hyphen-en-gb hyphen-en-us hyphen-es kaddressbook kamoso kget kgpg kid3 kio-gdrive kleopatra kolourpaint kompare krename krita krita-l10n krusader language-pack-es lhasa libavcodec-extra libdvd-pkg libfprint-2-2 libfprint-2-dev libfprint-2-doc libgegl-0.4-0 libgexiv2-2 libotr5 libpam-fprintd libreoffice-help-en-gb libreoffice-help-en-us libreoffice-help-es libreoffice-l10n-en-gb libreoffice-l10n-en-za libreoffice-l10n-es libreoffice-style-oxygen mythes-en-au mythes-en-us mythes-es nautilus-dropbox net-tools nfs-common openclipart-libreoffice openoffice.org-hyphenation pstoedit rar rpm rpm-i18n scdaemon signal-desktop steam telegram thunderbird-locale-en thunderbird-locale-es traceroute ubuntu-restricted-extras unace unrar-free vlc wspanish xboxdrv
dpkg-reconfigure libdvd-pkg
apt autoremove --purge -y skanlite xterm
snap remove --purge firefox
apt update
apt full-upgrade -y
echo -e "# Starts terminal with neofetch at the top\nneofetch" >> ~/.bashrc

# Check if the initial installation was successful
if [ $? -eq 0 ]; then
  echo "Initial installation successful."
else
  echo "Initial installation failed."
  exit 1
fi

# Prompt user for additional installations
while true; do
  echo "Available sets:"
  for set_name in "${!sets[@]}"; do
    echo "$set_name - ${sets[$set_name]}"
  done

  read -p "Enter the set of packages you want to install or 'exit' to quit: " choice

  if [ "$choice" == "exit" ]; then
    echo "Exiting."
    break
  fi

  if [ -n "${sets[$choice]}" ]; then
    install_packages "$choice"
  else
    echo "Invalid set name. Please choose from the available sets."
  fi
done

# Install Flatpak apps
install_flatpak_apps