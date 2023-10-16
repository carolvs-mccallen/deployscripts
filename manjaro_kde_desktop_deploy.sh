#!/bin/bash

# Check if the script is run as root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Associative array to store set names and explanations
declare -A sets
sets["development"]="This set includes common development tools, PyCharm Community Edition, RStudio and Wireshark."
sets["games"]="This set includes open source games, Heroic Launcher for Epic/GOG/Amazon games, and Steam."
sets["matroska"]="This set includes video editing utilities for multiple formats including Matroska"
sets["virt"]="This set includes RedHat Virtualization via Qemu and VirtualBox"
sets["k3b"]="This set includes K3b and CD/DVD burning utilities"

# Function to add repositories
add_repositories() {
  echo "Adding Flathub..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Function to install a set of packages
install_packages() {
  local set_name="$1"
  local packages=()

  case "$set_name" in
    "development")
      packages=(code notepadqq pycharm-community-edition r wireshark-qt)
      ;;
    "games")
      packages=(astromenace libretro-scummvm linux-steam-integration scummvm scummvm-tools steam steam-native-runtime supertux supertuxkart)
      ;;
    "matroska")
      packages=(handbrake mediainfo mediainfo-gui mkvtoolnix-gui)
      ;;
    "virt")
      packages=(virtualbox virtualbox-guest-iso virtualbox-host-dkms)
      ;;
    "k3b")
      packages=(cdrdao emovix k3b libisoburn sox vcdimager wavegain)
      ;;
    *)
      echo "Invalid set name. Exiting."
      exit 1
      ;;
  esac

  # Install the selected set of packages
  echo "Installing $set_name packages..."
   yes s | pacman -Sy --noconfirm "${packages[@]}"

  # Check if the installation was successful
  if [ $? -eq 0 ]; then
    echo "$set_name installation successful."

    # Run additional commands after set installation (if needed)
    if [ "$set_name" == "virt" ]; then
      echo "Completing virtualization packages setup..."
      usermod -aG vboxusers $USER
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
  read -p "Do you want to install Flatpak apps? (Y/N): " choice
  case "$choice" in
    [Yy]*)
      echo "Installing Flatpak apps..."
      flatpak install flathub -y org.gtk.Gtk3theme.Breeze com.jgraph.drawio.desktop com.google.Chrome com.microsoft.Edge com.github.opentyrian.OpenTyrian com.plexamp.Plexamp tv.plex.PlexDesktop com.ktechpit.whatsie us.zoom.Zoom
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
echo "Running initial Manjaro updates..."
yes s | pacman -Syu

# Add repositories and run commands before package selection
add_repositories

# Initial installation
echo "Updating package repository and installing initial packages..."
yes s | pacman -Sy akonadi-import-wizard arj bitwarden brave-browser btrfs-assistant btrfsmaintenance cabextract digikam discord discover dpkg falkon firefox-i18n-en-us firefox-i18n-es-mx fprintd gimp gimp-help-en gimp-help-es gimp-plugin-gmic qgit grub-btrfs gvfs-google hunspell-en_us hunspell-es_any hunspell-es_co hunspell-ex_mx innoextract kaddressbook kdiskmark kget kgpg kid3 kleopatra kmail kmail-account-wizard kmailtransport krename krita krita-plugin-gmic krusader ktorrent lhasa libfprint lshw man-pages-es nextcloud-client okteta pstoedit signal-desktop snapper snapper-gui spotify-launcher telegram-desktop unace unarj unrar
echo "Installing Popcorn Time..."
wget https://github.com/popcorn-time-ru/popcorn-desktop/releases/download/v0.4.9/Popcorn-Time-0.4.9-linux64.zip
mkdir /opt/popcorntime
unzip Popcorn-Time-0.4.9-linux64.zip -d /opt/popcorntime/
rm Popcorn-Time-0.4.9-linux64.zip
wget -O /opt/popcorntime/popcorn.png https://upload.wikimedia.org/wikipedia/commons/d/df/Pctlogo.png
ln -sf /opt/popcorntime/Popcorn-Time /usr/bin/Popcorn-Time
echo "Creating app list"
echo -e "[Desktop Entry]\nVersion=1.0\nType=Application\nTerminal=false\nName=Popcorn Time\nComment=Stream movies from the web\nExec=/usr/bin/Popcorn-Time\nIcon=/opt/popcorntime/popcorn.png\nCategories=AudioVideo;Player;Video" > /usr/share/applications/popcorntime.desktop
yes s | pacman -R skanlite
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