#!/bin/bash



#--------------------------------------------------------------------------------#
#                                                                                #
#                          Kali Linux on VPS                                     #
#                                                                                #
#  This script correctly sets up the Kali Linux repositories, updates the        #
#  system, and installs a list of essential penetration testing tools.           #
#                                                                                #
#  Author: Md Nahid Alam (@nahid0x1)                                             #
#  Date: 07-08-2025                                                              #
#                                                                                #
#--------------------------------------------------------------------------------#



# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file for debugging
LOGFILE="/var/log/kali_setup_script.log"
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# --- Function to print messages ---
print_msg() {
    case "$1" in
        "info") echo -e "${BLUE}[➤] $2${NC}" ;;
        "step") echo -e "${YELLOW}[•] $2${NC}" ;;
        "success") echo -e "${GREEN}[✓] $2${NC}" ;;
        "error") echo -e "${RED}[✘] $2${NC}" ;;
    esac
}

# --- Root Check ---
if [[ "$EUID" -ne 0 ]]; then
  print_msg "error" "Please run this script as root."
  exit 1
fi

print_msg "info" "Starting Kali Linux repository and tools setup..."
sleep 2

# --- Step 1: Backup and Setup Repository ---
print_msg "step" "Backing up old sources.list to /etc/apt/sources.list.bak..."
mv /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true

print_msg "step" "Downloading Kali's official GPG key..."
# The new recommended way to add the GPG key
wget -q -O /etc/apt/keyrings/kali-archive-keyring.gpg https://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2024.1_all.deb

print_msg "step" "Writing new Kali repository sources.list..."
# Using HTTPS directly and the new keyring
cat <<EOF > /etc/apt/sources.list
deb [signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg] https://http.kali.org/kali kali-rolling main non-free contrib non-free-firmware
deb-src [signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg] https://http.kali.org/kali kali-rolling main non-free contrib non-free-firmware
EOF

# --- Step 2: System Update and Upgrade ---
print_msg "step" "Updating APT package lists..."
if ! apt-get update; then
    print_msg "error" "APT update failed. Check the log at $LOGFILE for details."
    exit 1
fi

print_msg "step" "Performing a full system upgrade (this might take a while)..."
if ! apt-get full-upgrade -y; then
    print_msg "error" "Full upgrade failed. Check the log."
    exit 1
fi

# --- Step 3: Install Essential Tools ---
apt_tools=(
    python3 python3-pip git golang metasploit-framework massdns snapd nmap
    dnsutils jq npm chromium-browser fish parallel tmux unzip make gcc feroxbuster
    cewl dirb subfinder assetfinder httpx-toolkit nuclei-templates
)

pip_tools=(
    "knockpy"
    "sublist3r"
    "arjun"
    "photon"
)

print_msg "step" "Installing tools via APT..."
if ! apt-get install -y "${apt_tools[@]}"; then
    print_msg "error" "Failed to install some APT tools. Check the log."
    # The script will continue to try installing other tools
fi

print_msg "step" "Installing Python tools via pip..."
if ! python3 -m pip install "${pip_tools[@]}"; then
    print_msg "error" "Failed to install some Python tools via pip. Check the log."
fi

# --- Step 4: System Cleanup ---
print_msg "step" "Removing old and unused packages..."
apt-get autoremove --purge -y

print_msg "step" "Cleaning up APT cache..."
apt-get clean

# --- Step 5: Configure Go Path ---
# This part is for the user who will be using Go tools.
# Note: The script is run as root, so this applies to the root user's environment.
print_msg "step" "Adding Go binary path to root's shell configurations..."
if ! grep -q 'export PATH="$PATH:/root/go/bin"' /root/.bashrc; then
    echo '' >> /root/.bashrc
    echo '# Go language path' >> /root/.bashrc
    echo 'export PATH="$PATH:/root/go/bin"' >> /root/.bashrc
fi

if [ -f /root/.zshrc ] && ! grep -q 'export PATH="$PATH:/root/go/bin"' /root/.zshrc; then
    echo '' >> /root/.zshrc
    echo '# Go language path' >> /root/.zshrc
    echo 'export PATH="$PATH:/root/go/bin"' >> /root/.zshrc
fi
print_msg "info" "Go path added for the root user. Please add 'export PATH=\$PATH:~/go/bin' to your regular user's .bashrc or .zshrc if needed."


# --- Finalization ---
print_msg "success" "Kali Linux setup and tool installation is complete!"
print_msg "info" "A log file is available at $LOGFILE"

read -p "A reboot is recommended to apply all changes. Reboot now? (y/N): " choice
case "$choice" in
  y|Y )
    print_msg "info" "Rebooting system..."
    reboot
    ;;
  * )
    print_msg "info" "Please reboot the system manually later."
    ;;
esac

exit 0
