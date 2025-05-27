#!/bin/bash

# Fedora Post-Install Setup Script
# This script configures a fresh Fedora installation with essential software and optimizations

set -e # Exit on any error

echo "🚀 Starting Fedora Post-Install Configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# 1. System Update
print_status "Updating system packages..."
sudo dnf update -y
print_success "System updated successfully"

# 2. Configure DNF for better performance
print_status "Optimizing DNF configuration..."
sudo tee -a /etc/dnf/dnf.conf >/dev/null <<EOF

# Performance optimizations
max_parallel_downloads=10
fastestmirror=True
deltarpm=True
EOF
print_success "DNF optimized for faster downloads"

# 3. Enable RPM Fusion repositories
print_status "Enabling RPM Fusion repositories..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
print_success "RPM Fusion repositories enabled"

# 4. Enable additional useful repositories
print_status "Enabling additional repositories..."
sudo dnf config-manager --set-enabled fedora-cisco-openh264
print_success "Additional repositories enabled"

# 5. Enable Flathub
print_status "Enabling Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
print_success "Flathub repository enabled"

# 6. Install multimedia codecs and essential packages
print_status "Installing multimedia codecs and essential packages..."
sudo dnf install -y \
  @multimedia \
  ffmpeg \
  gstreamer1-plugins-{bad-*,good-*,base} \
  gstreamer1-plugin-openh264 \
  gstreamer1-libav \
  lame* \
  --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf update -y @core
print_success "Multimedia codecs installed"

# 7. Install essential development tools
print_status "Installing development tools..."
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
  git \
  curl \
  wget \
  vim \
  neofetch \
  htop \
  tree \
  unzip \
  p7zip \
  p7zip-plugins
print_success "Development tools installed"

# 8. Install required packages
print_status "Installing required packages..."
REQUIRED_PACKAGES=(
  "gnome-tweaks"
  "bottles"
  "wine"
  "steam"
  "preload" # For faster app startup
)

for package in "${REQUIRED_PACKAGES[@]}"; do
  if sudo dnf install -y "$package"; then
    print_success "Installed $package"
  else
    print_warning "Failed to install $package, skipping..."
  fi
done

# 9. Install packages from pkg.txt if it exists
if [[ -f "pkg.txt" ]]; then
  print_status "Installing packages from pkg.txt..."
  while IFS= read -r package; do
    if [[ -n "$package" && ! "$package" =~ ^#.* ]]; then
      if sudo dnf install -y "$package"; then
        print_success "Installed $package"
      else
        print_warning "Failed to install $package, skipping..."
      fi
    fi
  done <pkg.txt
  print_success "Finished installing packages from pkg.txt"
else
  print_warning "pkg.txt not found, skipping package installation from file"
fi

# 10. Install Flatpak packages
print_status "Installing required Flatpak packages..."
FLATPAK_PACKAGES=(
  "com.discordapp.Discord"
)

for package in "${FLATPAK_PACKAGES[@]}"; do
  if flatpak install -y flathub "$package"; then
    print_success "Installed Flatpak: $package"
  else
    print_warning "Failed to install Flatpak: $package, skipping..."
  fi
done

# 11. Install Flatpak packages from fpk.txt if it exists
if [[ -f "fpk.txt" ]]; then
  print_status "Installing Flatpak packages from fpk.txt..."
  while IFS= read -r package; do
    if [[ -n "$package" && ! "$package" =~ ^#.* ]]; then
      if flatpak install -y flathub "$package"; then
        print_success "Installed Flatpak: $package"
      else
        print_warning "Failed to install Flatpak: $package, skipping..."
      fi
    fi
  done <fpk.txt
  print_success "Finished installing Flatpak packages from fpk.txt"
else
  print_warning "fpk.txt not found, skipping Flatpak installation from file"
fi

# 12. Font Installation and Configuration
print_status "Installing and configuring fonts..."

# Create fonts directory
mkdir -p ~/.local/share/fonts/inter
mkdir -p ~/.local/share/fonts/jetbrains-mono

# Install Inter font
print_status "Downloading and installing Inter font..."
curl -L https://github.com/rsms/inter/releases/latest/download/Inter.zip -o /tmp/Inter.zip
unzip /tmp/Inter.zip -d /tmp/Inter
find /tmp/Inter -name "*.ttf" -exec cp {} ~/.local/share/fonts/inter/ \;
rm -rf /tmp/Inter /tmp/Inter.zip

# Install JetBrains Mono font
print_status "Downloading and installing JetBrains Mono font..."
curl -L https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip -o /tmp/JetBrainsMono.zip
unzip /tmp/JetBrainsMono.zip -d /tmp/JetBrainsMono
find /tmp/JetBrainsMono -name "*.ttf" -exec cp {} ~/.local/share/fonts/jetbrains-mono/ \;
rm -rf /tmp/JetBrainsMono /tmp/JetBrainsMono.zip

# Update font cache
fc-cache -f -v

# Set system fonts using gsettings
print_status "Configuring system fonts..."
gsettings set org.gnome.desktop.interface font-name 'Inter 11'
gsettings set org.gnome.desktop.interface document-font-name 'Inter 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Medium 11'

print_success "Fonts installed and configured"

# 13. Additional Quality-of-Life Improvements
print_status "Applying additional quality-of-life improvements..."

# Enable automatic updates
gsettings set org.gnome.software download-updates true
gsettings set org.gnome.software download-updates-notify true

# Configure better DNS (Cloudflare)
print_status "Configuring better DNS servers..."
sudo tee /etc/systemd/resolved.conf >/dev/null <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
FallbackDNS=8.8.8.8 8.8.4.4
DNSSEC=yes
Cache=yes
EOF

sudo systemctl restart systemd-resolved

# Install useful GNOME extensions (optional)
print_status "Installing useful GNOME Shell extensions..."
sudo dnf install -y gnome-extensions-app

# Enable and start preload service
sudo systemctl enable preload
sudo systemctl start preload

# Install additional useful applications
print_status "Installing additional useful applications..."
ADDITIONAL_APPS=(
  "gnome-extensions-app"
  "dconf-editor"
  "timeshift"
  "keepassxc"
  "firefox"
  "thunderbird"
  "libreoffice"
  "gimp"
  "vlc"
  "transmission"
)

for app in "${ADDITIONAL_APPS[@]}"; do
  if sudo dnf install -y "$app" 2>/dev/null; then
    print_success "Installed $app"
  else
    print_warning "Failed to install $app or already installed"
  fi
done

# 14. Performance optimizations
print_status "Applying performance optimizations..."

# Configure swappiness for better performance
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# 15. Security improvements
print_status "Applying security improvements..."
sudo dnf install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

# 16. Final system update
print_status "Performing final system update..."
sudo dnf update -y

print_success "🎉 Fedora post-install configuration completed successfully!"
