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
sets["brasero"]="This set includes Brasero and CD/DVD burning utilities"

# Function to add repositories
add_repositories() {
  echo "Adding repositories..."
  echo "Adding Brave Browser repository..."
  curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg  | apt-key add -
  echo -e "#Brave Browser\ndeb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list
  echo "Adding GIMP PPA"
  add-apt-repository -y ppa:ubuntuhandbook1/gimp
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
      packages=(bless code libclang-dev libssl-dev libxml2-dev meld notepadqq pycharm-community r-base wireshark wireshark-common wireshark-doc wireshark-gtk)
      ;;
    "games")
      packages=(aisleriot astromenace chromium-bsu frozen-bubble lgc-pg lgogdownloader opentyrian scummvm scummvm-data scummvm-tools steam supertux supertuxkart supertuxkart-data)
      ;;
    "matroska")
      packages=(handbrake mediainfo-gui mkvtoolnix-gui)
      ;;
    "virt")
      packages=(virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso virtualbox-guest-utils-hwe virtualbox-guest-x11-hwe)
      ;;
    "brasero")
      packages=(burner-cdrkit cdrskin dvd+rw-tools gstreamer1.0-plugins-bad libsox-fmt-all brasero normalize-audio sox tracker vcdimager xorriso)
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
    elif [ "$set_name" == "brasero" ]; then
      echo "Completing Brasero packages setup..."
      usermod -aG cdrom $USER
    fi
  else
    echo "$set_name installation failed."
  fi
}

# Function to install Flatpak apps
install_flatpak_apps() {
  read -p "Do you want to install Flatpak apps? (Y/N): " choice
  case "$choice" in
    [Yy]*)
      echo "Installing Flatpak apps..."
      flatpak install flathub -y org.gtk.Gtk3theme.Mint-Y org.gtk.Gtk3theme.Mint-Y-Aqua org.gtk.Gtk3theme.Mint-Y-Blue org.gtk.Gtk3theme.Mint-Y-Brown org.gtk.Gtk3theme.Mint-Y-Dark org.gtk.Gtk3theme.Mint-Y-Darker org.gtk.Gtk3theme.Mint-Y-Dark-Aqua org.gtk.Gtk3theme.Mint-Y-Darker-Aqua org.gtk.Gtk3theme.Mint-Y-Dark-Blue org.gtk.Gtk3theme.Mint-Y-Darker-Blue org.gtk.Gtk3theme.Mint-Y-Dark-Brown org.gtk.Gtk3theme.Mint-Y-Darker-Brown org.gtk.Gtk3theme.Mint-Y-Dark-Grey org.gtk.Gtk3theme.Mint-Y-Darker-Grey org.gtk.Gtk3theme.Mint-Y-Dark-Orange org.gtk.Gtk3theme.Mint-Y-Darker-Orange org.gtk.Gtk3theme.Mint-Y-Dark-Pink org.gtk.Gtk3theme.Mint-Y-Darker-Pink org.gtk.Gtk3theme.Mint-Y-Dark-Purple org.gtk.Gtk3theme.Mint-Y-Darker-Purple org.gtk.Gtk3theme.Mint-Y-Dark-Red org.gtk.Gtk3theme.Mint-Y-Darker-Red org.gtk.Gtk3theme.Mint-Y-Dark-Sand org.gtk.Gtk3theme.Mint-Y-Darker-Sand org.gtk.Gtk3theme.Mint-Y-Dark-Teal org.gtk.Gtk3theme.Mint-Y-Darker-Teal org.gtk.Gtk3theme.Mint-Y-Grey org.gtk.Gtk3theme.Mint-Y-Orange org.gtk.Gtk3theme.Mint-Y-Pink org.gtk.Gtk3theme.Mint-Y-Purple org.gtk.Gtk3theme.Mint-Y-Red org.gtk.Gtk3theme.Mint-Y-Sand org.gtk.Gtk3theme.Mint-Y-Teal com.bitwarden.desktop com.discordapp.Discord com.plexamp.Plexamp tv.plex.PlexDesktop com.spotify.Client com.ktechpit.whatsie io.github.JaGoLi.ytdl_gui
      echo "Applying automatic theme selection for Flatpak apps"
      flatpak override --filesystem=xdg-config/gtk-3.0:ro
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
echo "Running initial Mint updates..."
apt update
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
apt install --install-recommends -y alien arj brave-browser cheese doublecmd-gtk eog eog-plugins epiphany-browser epiphany-browser-data evolution frei0r-plugins firefox-locale-es gimp gimp-data-extras gimp-help-common gimp-help-en gimp-help-es git git-cvs git-daemon-run git-doc git-email git-gui git-mediawiki git-svn gitk gnome-contacts gnome-mahjongg gnome-maps gnome-mines gnome-video-effects-frei0r gnome-weather gpa hashdeep hyphen-es hyphen-fi hyphen-ga hyphen-id kid3-qt language-pack-es language-pack-gnome-es lhasa libdvd-pkg libfprint-2-dev libfprint-2-doc libgegl-0.4-0 libgegl-common libmypaint-1.5-1 libmypaint-common libncurses5 libncurses5:i386 libpam-fprintd linux-generic-hwe-22.04 linux-headers-generic-hwe-22.04 linux-image-generic-hwe-22.04 malcontent-gui mint-meta-codecs mythes-es nautilus-dropbox nemo-nextcloud nextcloud-desktop nextcloud-desktop-common nextcloud-desktop-doc nextcloud-desktop-l10n nfs-common openclipart-libreoffice openoffice.org-hyphenation pstoedit rar rpm rpm-i18n signal-desktop telegram-desktop traceroute uget unace unrar-free vlc xboxdrv
dpkg-reconfigure libdvd-pkg
apt autoremove --purge -y celluloid* simple-scan* thunderbird*
echo "export QT_QPA_PLATFORMTHEME=gtk2" >> ~/.profile
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