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
  echo "Adding repositories..."
  echo "Installing RPMFusion..."
  dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  echo "Adding Brave Browser repository..."
  dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
  rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  echo "Adding Microsoft VSCode and Edge repositories..."
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
  echo "Adding Heroic Launcher repository..."
  dnf copr enable -y atim/heroic-games-launcher
  echo "Adding PyCharm Community repository..."
  dnf copr enable -y phracek/PyCharm
  echo "Adding Google Chrome repository..."
  dnf config-manager --set-enabled google-chrome
  echo "Adding Steam (RPMFusion) repository..."
  dnf config-manager --set-enabled rpmfusion-nonfree-steam
  echo "Adding Nvidia Drivers (RPMFusion) repository..."
  dnf config-manager --set-enabled rpmfusion-nonfree-nvidia-driver
  echo "Adding Flathub..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Function to install a set of packages
install_packages() {
  local set_name="$1"
  local packages=()

  case "$set_name" in
    "development")
      packages=(code @development-tools kommit pycharm-community pycharm-community-doc pycharm-community-plugins R rstudio-desktop wireshark)
      ;;
    "games")
      packages=(astromenace frozen-bubble heroic-games-launcher-bin lutris scummvm scummvm-data scummvm-tools steam supertux supertuxkart supertuxkart-data)
      ;;
    "matroska")
      packages=(handbrake handbrake-gui mediainfo-gui mkvtoolnix-gui)
      ;;
    "virt")
      packages=(akmod-VirtualBox kmod-VirtualBox qemu VirtualBox @Virtualization)
      ;;
    "k3b")
      packages=(cdrskin k3b normalize sox transcode vcdimager xorriso)
      ;;
    *)
      echo "Invalid set name. Exiting."
      exit 1
      ;;
  esac

  # Install the selected set of packages
  echo "Installing $set_name packages..."
   dnf install --best --allowerasing -y "${packages[@]}"

  # Check if the installation was successful
  if [ $? -eq 0 ]; then
    echo "$set_name installation successful."

    # Run additional commands after set installation (if needed)
    if [ "$set_name" == "games" ]; then
      echo "Completing game packages setup..."
      su -c "setsebool -P allow_execheap 1"
    elif [ "$set_name" == "virt" ]; then
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
      flatpak install flathub -y org.gtk.Gtk3theme.Breeze com.bitwarden.desktop com.discordapp.Discord com.github.opentyrian.OpenTyrian com.plexamp.Plexamp tv.plex.PlexDesktop org.signal.Signal com.spotify.Client com.ktechpit.whatsie io.github.JaGoLi.ytdl_gui
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
echo "Improving DNF performance..."
echo -e "#Improve DNF download speed and performance\nmax_parallel_downloads=10\nfastestmirror=True\ninstallonly_limit=2" >> /etc/dnf/dnf.conf
echo "Running initial Fedora updates..."
dnf update -y

# Add repositories and run commands before package selection
add_repositories

# Initial installation
echo "Updating package repository and installing initial packages..."
dnf update -y
dnf install -y https://github.com/jgraph/drawio-desktop/releases/download/v22.0.2/drawio-x86_64-22.0.2.rpm https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm https://binaries.webex.com/WebexDesktop-CentOS-Official-Package/Webex.rpm https://zoom.us/client/5.16.2.8828/zoom_x86_64.rpm
dnf install --best --allowerasing -y arj brave-browser btrfs-assistant btrfsmaintenance cabextract digikam dnf-utils dolphin-megasync dpkg dropbox falkon fprintd-devel gimp gimp-data-extras gimp-*-plugin gimp-elsamuko gimp-*-filter gimp-help gimp-help-es gimp-layer* gimp-lensfun gimp-*-masks gimp-resynthesizer gimp-save-for-web gimp-separate+ gimp-*-studio gimp-wavelet* gimpfx-foundry git git-core google-chrome-stable htop hunspell hunspell-es info innoextract kate kde-l10n-es kdiff3 kdiskmark kernel-devel kernel-headers kget kid3 kleopatra krename krita krusader ksystemlog ktorrent lha libcurl-devel libreoffice-langpack-es libreoffice-help-es libfprint-devel libxml2-devel lshw lzma megasync microsoft-edge-stable mozilla-ublock-origin neofetch nextcloud-client nextcloud-client-dolphin nodejs-bash-language-server openssl-devel okteta perl pstoedit python3-dnf-plugin-snapper redhat-lsb-core snapper telegram-desktop tracker unace unrar vlc vlc-bittorrent vlc-extras xkill
echo "Installing Popcorn Time..."
wget https://github.com/popcorn-time-ru/popcorn-desktop/releases/download/v0.4.9/Popcorn-Time-0.4.9-linux64.zip
mkdir /opt/popcorntime
unzip Popcorn-Time-0.4.9-linux64.zip -d /opt/popcorntime/
rm Popcorn-Time-0.4.9-linux64.zip
wget -O /opt/popcorntime/popcorn.png https://github.com/carolvs-mccallen/testground/blob/main/icon.png?raw=true
ln -sf /opt/popcorntime/Popcorn-Time /usr/bin/Popcorn-Time
echo "Creating app list"
echo -e "[Desktop Entry]\nVersion=1.0\nType=Application\nTerminal=false\nName=Popcorn Time\nComment=Stream movies from the web\nExec=/usr/bin/Popcorn-Time\nIcon=/opt/popcorntime/popcorn.png\nCategories=AudioVideo;Player;Video" > /usr/share/applications/popcorntime.desktop
dnf remove -y dragon virtualbox-guest-additions
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