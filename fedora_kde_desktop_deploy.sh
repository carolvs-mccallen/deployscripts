#!/bin/bash

# Check if the script is run as root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Capture the output of the logname command
USER=$(logname)

# Prompt user to select GPU type
echo "Please select your GPU:"
echo "1) NVIDIA"
echo "2) Skip GPU installation"
read -p "Enter your choice [1-2]: " gpu_choice

# Function to add repositories
add_repositories() {
  echo "Adding repositories..."
  echo "Installing RPMFusion..."
  dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  echo "Adding Brave Browser repository..."
  rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
  echo "Adding GitHub CLI repository..."
  dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
  echo "Adding Google Chrome repository..."
  dnf config-manager enable google-chrome
  echo "Adding Slack repository..."
  rpm --import https://slack.com/gpg/slack_pubkey_20260921.gpg
  dnf config-manager addrepo --from-repofile=https://raw.githubusercontent.com/carolvs-mccallen/deployscripts/refs/heads/main/slack.repo
  echo "Adding TeamViewer repository..."
  rpm --import https://linux.teamviewer.com/pubkey/currentkey.asc
  dnf config-manager addrepo --from-repofile=https://raw.githubusercontent.com/carolvs-mccallen/deployscripts/refs/heads/main/teamviewer.repo
  echo "Adding Flatpark and Flathub repositories..."
  flatpak remote-add --if-not-exists flatpark https://dl.flatpark.org/flatpark.flatpakrepo
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Function to install GPU drivers
install_gpu_drivers() {
  if [ "$gpu_choice" -eq 1 ]; then
    echo "Adding NVIDIA repositories"
    dnf config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora$(rpm -E %fedora)/x86_64/cuda-fedora$(rpm -E %fedora).repo
    dnf config-manager addrepo --from-repofile=https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
    echo "Installing NVIDIA drivers and CUDA..."
    dnf -y install cuda-toolkit kernel-devel-matched kernel-headers kmod-nvidia-open-dkms nvidia-container-toolkit nvidia-gds nvidia-open nvidia-driver nvidia-driver-cuda
    echo "NVIDIA drivers and CUDA installed successfully."

  elif [ "$gpu_choice" -eq 2 ]; then
    echo "Skipping GPU installation."

  else
    echo "Invalid choice. Exiting."
    exit 1
  fi
}

# Associative array to store set names and explanations
declare -A sets
sets["artcraft"]="This set replaces LibreOffice with the ArtCraft Office utilities."
sets["development"]="This set includes common development tools, PyCharm Community Edition, RStudio and Wireshark."
sets["displaylink"]="This set installs DisplayLink software and drivers."
sets["games"]="This set includes open source games, Heroic Launcher for Epic/GOG/Amazon games, and Steam."
sets["k3b"]="This set includes K3b and CD/DVD burning utilities"
sets["matroska"]="This set includes video editing utilities for multiple formats including Matroska"
sets["virt"]="This set includes RedHat Virtualization via Qemu and VirtualBox"


# Function to install a set of packages
install_packages() {
  local set_name="$1"
  local packages=()

  case "$set_name" in
    "artcraft")
      packages=(wordcraft deckcraft gridcraft pdfcraft)
      ;;
    "development")
      packages=(codium @development-tools kommit pycharm-community pycharm-community-doc pycharm-community-plugins R rstudio-desktop wireshark)
      ;;
    "displaylink")
      packages=(displaylink)
      ;;
    "games")
      packages=(astromenace frozen-bubble heroic-games-launcher-bin lutris scummvm scummvm-data scummvm-tools steam supertux supertuxkart supertuxkart-data xpadneo)
      ;;
    "k3b")
      packages=(cdrskin k3b normalize sox transcode vcdimager xorriso)
      ;;
    "matroska")
      packages=(handbrake handbrake-gui mediainfo-gui mkvtoolnix-gui)
      ;;
    "virt")
      packages=(qemu VirtualBox-7.2 @virtualization)
      ;;
    *)
      echo "Invalid set name. Exiting."
      exit 1
      ;;
  esac

  # Add only the repositories required by the selected set
  case "$set_name" in
    "artcraft")
      echo "Adding the ArtCraft repository..."
      dnf config-manager addrepo --from-repofile=https://getartcraft.com/rpm/artcraft.repo
      echo "Removing LibreOffice packages..."
      dnf remove -y @libreoffice libreoffice-core libreoffice-langpack-es libreoffice-help-es
      ;;
    "development")
      echo "Adding the PyCharm, RStudio and VSCodium repositories..."
      dnf copr enable -y phracek/PyCharm
      dnf copr enable -y iucar/rstudio
      dnf config-manager addrepo --from-repofile=https://raw.githubusercontent.com/carolvs-mccallen/deployscripts/refs/heads/main/vscodium.repo
      ;;
    "displaylink")
      echo "Adding the DisplayLink repository..."
      dnf copr enable -y crashdummy/Displaylink
      ;;
    "games")
      echo "Adding the Heroic Games Launcher and Steam repositories..."
      dnf copr enable -y atim/heroic-games-launcher
      dnf config-manager enable rpmfusion-nonfree-steam
      dnf copr enable -y atim/xpadneo
      ;;
    "virt")
      echo "Adding the VirtualBox repository..."
      dnf config-manager addrepo --from-repofile=https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
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
      setsebool -P allow_execheap 1
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
      flatpak install flathub -y org.gtk.Gtk3theme.Breeze com.bitwarden.desktop com.discordapp.Discord com.jgraph.drawio.desktop com.github.opentyrian.OpenTyrian com.plexamp.Plexamp tv.plex.PlexDesktop io.podman_desktop.PodmanDesktop org.signal.Signal com.spotify.Client us.zoom.Zoom
      flatpak install flatpark -y com.automattic.Beeper
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

# Improve DNF performance
echo "Improving DNF performance..."
echo -e "#Improve DNF download speed and performance\nmax_parallel_downloads=10\nfastestmirror=True\ninstallonly_limit=2" >> /etc/dnf/dnf.conf

# Add repositories and run commands before package selection
add_repositories

# Run the GPU driver installation
install_gpu_drivers
echo "Running initial Fedora updates..."
dnf update -y

# Initial installation
echo "Installing software for user: $USER"
echo "Updating package repository and installing initial packages..."
dnf update -y
dnf install -y https://binaries.webex.com/WebexDesktop-CentOS-Official-Package/Webex.rpm
dnf install --best --allowerasing -y arj awesome-vim-colorschemes azure-cli brave-browser btrfs-assistant btrfsmaintenance cabextract digikam dolphin-megasync dpkg dropbox falkon fastfetch fprintd-devel gh gimp gimp-data-extras gimp-fourier-plugin gimp-elsamuko gimp-*-filter gimp-help gimp-help-es gimp-*-masks gimp-resynthesizer gimp-*-studio gimpfx-foundry git git-core google-chrome-stable htop hunspell hunspell-es info innoextract kate kde-l10n-es kdiff3 kdiskmark kget kid3 kleopatra krename krita krusader ksystemlog ktorrent kubernetes-client lha libcurl-devel libdrm-devel libfprint-devel libpciaccess-devel libreoffice-langpack-es libreoffice-help-es libxml2-devel lshw lzma megasync mozilla-ublock-origin nextcloud-client nextcloud-client-dolphin nodejs-bash-language-server openssl-devel okteta perl podman-docker pstoedit python3-dnf-plugin-snapper python3-pip slack snapper teamviewer telegram-desktop tracker unace unrar vim-enhanced @vlc xkill
dnf remove -y dragon @guest-desktop-agents
echo -e "# Starts terminal with fastfetch at the top\nfastfetch" >> /home/$USER/.bashrc

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
dnf clean all