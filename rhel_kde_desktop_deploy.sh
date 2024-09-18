#!/bin/bash

# Check if the script is run as root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Prompt for username and password
read -p "Enter your RHEL username: " username
read -sp "Enter your RHEL password: " password
echo

# Function to manage subscriptions
manage_subscription() {
  echo "Managing subscription for $username..."
  # This takes the collected username and password for RHEL subscription and enables it.
  subscription-manager register --username "$username" --password "$password" --auto-attach
  echo "Subscription management complete."
}

# Capture the output of the logname command
USER=$(logname)

# Prompt user to select GPU type
echo "Please select your GPU:"
echo "1) NVIDIA"
echo "2) AMD Radeon"
echo "3) Skip GPU installation"
read -p "Enter your choice [1-3]: " gpu_choice

# Function to add repositories
add_repositories() {
  echo "Adding repositories..."
  echo "Enabling CRB"
  subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
  echo "Installing ELrepo, EPEL and RPMFusion..."
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  dnf install -y https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
  dnf install --nogpgcheck -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm
  dnf install --nogpgcheck -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
  echo "Adding Brave Browser repository..."
  rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
  echo "Adding Google Chrome repository..."
  rpm --import https://dl.google.com/linux/linux_signing_key.pub
  echo "Adding Heroic Launcher repository..."
  dnf copr enable -y atim/heroic-games-launcher
  echo "Adding Microsoft VSCode and Edge repositories..."
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/vscode
  dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
  echo "Adding PyCharm Community repository..."
  dnf copr enable -y phracek/PyCharm
  echo "Adding Flathub..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Function to install GPU drivers
install_gpu_drivers() {
  if [ "$gpu_choice" -eq 1 ]; then
    echo "Installing NVIDIA drivers and CUDA..."
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    dnf -y module install --best --allowerasing nvidia-driver:latest-dkms
    dnf -y install cuda-toolkit nvidia-container-toolkit nvidia-gds
    echo "NVIDIA drivers and CUDA installed successfully."

  elif [ "$gpu_choice" -eq 2 ]; then
    echo "Installing AMD Radeon drivers..."
    dnf -y install https://repo.radeon.com/amdgpu-install/6.1.2/rhel/9.4/amdgpu-install-6.1.60102-1.el9.noarch.rpm
    dnf -y install --best --allowerasing amdgpu-dkms rocm
    usermod -aG render,video $USER
    echo "AMD Radeon drivers installed successfully."

  elif [ "$gpu_choice" -eq 3 ]; then
    echo "Skipping GPU installation."
  else
    echo "Invalid choice. Exiting."
    exit 1
  fi
}

# Execute the subscription management and repository addition functions
manage_subscription
add_repositories

# Run the GPU driver installation
install_gpu_drivers

# Associative array to store set names and explanations
declare -A sets
sets["development"]="This set includes common development tools, PyCharm Community Edition, R and Wireshark."
sets["games"]="This set includes open source games, Heroic Launcher for Epic/GOG/Amazon games, and Steam."
sets["matroska"]="This set includes video editing utilities for multiple formats including Matroska"
sets["virt"]="This set includes RedHat Virtualization via Qemu and VirtualBox"
sets["k3b"]="This set includes K3b and CD/DVD burning utilities"

# Function to install a set of packages
install_packages() {
  local set_name="$1"
  local packages=()

  case "$set_name" in
}    "development")
      packages=(code pycharm-community pycharm-community-doc pycharm-community-plugins R wireshark)
      ;;
    "games")
      packages=(heroic-games-launcher-bin lutris steam)
      ;;
    "matroska")
      packages=(mediainfo-gui)
      ;;
    "virt")
      packages=(akmod-VirtualBox kmod-VirtualBox VirtualBox)
      ;;
    "k3b")
      packages=(cdrskin k3b sox vcdimager xorriso)
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
    if  [ "$set_name" == "development" ]; then
      echo "Completing development packages setup..."
      flatpak install -y flathub org.kde.kommit
    elif [ "$set_name" == "games" ]; then
      echo "Completing game packages setup..."
      flatpak install -y flathub com.viewizard.AstroMenace org.frozen_bubble.frozen-bubble com.github.opentyrian.OpenTyrian org.scummvm.ScummVM org.supertuxproject.SuperTux net.supertuxkart.SuperTuxKart
      setsebool -P allow_execheap 1
    elif [ "$set_name" == "matroska" ]; then
      echo "Completing Matroska packages setup..."
      flatpak install -y flathub fr.handbrake.ghb org.bunkus.mkvtoolnix-gui
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

# Running pre-requisite upgrade
echo "Improving DNF performance..."
echo -e "#Improve DNF download speed and performance\nmax_parallel_downloads=10\nfastestmirror=True\ninstallonly_limit=2" >> /etc/dnf/dnf.conf
echo "Running initial RHEL updates..."
dnf update -y

# Initial installation
echo "Installing software for user: $USER"
echo "Updating package repository and installing initial packages..."
dnf update -y
dnf groupinstall -y "KDE Plasma Workspaces" "KDE Applications" "base-x" "VideoLAN Client"
# systemctl disable gdm
# systemctl enable sddm
dnf install -y https://github.com/jgraph/drawio-desktop/releases/download/v24.7.8/drawio-x86_64-24.7.8.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm https://binaries.webex.com/WebexDesktop-CentOS-Official-Package/Webex.rpm https://zoom.us/client/latest/zoom_x86_64.rpm
dnf install --best --allowerasing -y arj azure-cli brave-browser cabextract deja-dup digikam dnf-utils dpkg gcc-go gnupg2-smime golang-bin google-chrome-stable htop innoextract kate kamoso kdiff3 kdiskmark kleopatra krename krusader ksystemlog ktorrent libcurl-devel libxml2-devel lzma microsoft-edge-stable neofetch nextcloud-client nextcloud-client-dolphin openssl-devel okteta perl podman-docker pstoedit python3-pip thunderbird tracker unrar vim-enhanced xkill
flatpak install flathub -y org.gtk.Gtk3theme.Breeze com.dropbox.Client com.bitwarden.desktop com.discordapp.Discord org.gimp.GIMP org.kde.kget org.kde.kid3 org.kde.krita org.libreoffice.LibreOffice nz.mega.MEGAsync md.obsidian.Obsidian com.plexamp.Plexamp tv.plex.PlexDesktop org.signal.Signal com.slack.Slack com.spotify.Client org.telegram.desktop
echo "Applying automatic theme selection for Flatpak apps"
flatpak override --filesystem=xdg-config/gtk-3.0:ro
echo "Installing Popcorn Time..."
wget https://github.com/popcorn-official/popcorn-desktop/releases/download/v0.5.1/Popcorn-Time-0.5.1-linux64-0.44.5.zip
mkdir /opt/popcorntime
unzip Popcorn-Time-0.5.1-linux64-0.44.5.zip -d /opt/popcorntime/
rm Popcorn-Time-0.5.1-linux64-0.44.5.zip
wget -O /opt/popcorntime/popcorn.png https://github.com/carolvs-mccallen/deployscripts/blob/main/icon.png?raw=true
ln -sf /opt/popcorntime/Popcorn-Time /usr/bin/Popcorn-Time
echo "Creating app list"
echo -e "[Desktop Entry]\nVersion=1.0\nType=Application\nTerminal=false\nName=Popcorn Time\nComment=Stream movies from the web\nExec=/usr/bin/Popcorn-Time\nIcon=/opt/popcorntime/popcorn.png\nCategories=AudioVideo;Player;Video" > /usr/share/applications/popcorntime.desktop
dnf remove -y dragon kmail open-vm-tools* virtualbox-guest-additions
echo -e "# Starts terminal with neofetch at the top\nneofetch" >> /home/$USER/.bashrc
echo "Adding Python langchain modules"
pip install langchain-community

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
