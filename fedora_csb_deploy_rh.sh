#!/bin/bash

# Check if the script is run as root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Function to add repositories
add_repositories() {
  echo "Adding repositories..."
  echo "Installing RPMFusion..."
  dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  echo "Adding Microsoft repository..."
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
}

# Function to install Flatpak apps
install_flatpak_apps() {
  read -p "Do you want to install Flatpak apps? (Y/N): " choice
  case "$choice" in
    [Yy]*)
      echo "Installing Flatpak apps..."
      flatpak install flathub -y com.bitwarden.desktop com.spotify.Client
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
dnf install -y https://github.com/displaylink-rpm/displaylink-rpm/releases/download/v5.8.0/fedora-38-displaylink-1.14.1-1.x86_64.rpm https://downloads.slack-edge.com/releases/linux/4.35.126/prod/x64/slack-4.35.126-0.1.el8.x86_64.rpm https://binaries.webex.com/WebexDesktop-CentOS-Official-Package/Webex.rpm https://zoom.us/client/5.16.2.8828/zoom_x86_64.rpm
dnf install --best --allowerasing -y arj cabextract code @development-tools dnf-utils dpkg fprintd-devel gedit gimp gimp-data-extras gimp-*-plugin gimp-elsamuko gimp-*-filter gimp-help gimp-help-es gimp-layer* gimp-lensfun gimp-*-masks gimp-resynthesizer gimp-save-for-web gimp-separate+ gimp-*-studio gimp-wavelet* gimpfx-foundry gitg htop hunspell hunspell-es info innoextract kernel-devel kernel-headers lha libcurl-devel libreoffice-langpack-es libreoffice-help-es libfprint-devel libxml2-devel lshw lzma microsoft-edge-stable mozilla-ublock-origin neofetch nodejs-bash-language-server openssl-devel perl pstoedit pycharm-community pycharm-community-doc pycharm-community-plugins redhat-lsb-core thunderbird tracker unace unrar wireshark xkill

# Check if the initial installation was successful
if [ $? -eq 0 ]; then
  echo "Initial installation successful."
else
  echo "Initial installation failed."
  exit 1
fi

# Install Flatpak apps
install_flatpak_apps
