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



# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file
LOGFILE="/var/log/kali_repo_setup.log"
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"

# Root check
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${RED}[✘] Please run this script as root.${NC}"
  exit 1
fi

echo -e "${YELLOW}[➤] Starting Kali repository setup...${NC}"

# Step 1: Create keyrings directory
echo -e "${YELLOW}[•] Creating /etc/apt/keyrings...${NC}"
mkdir -p /etc/apt/keyrings || {
  echo -e "${RED}[✘] Failed to create keyrings directory.${NC}" | tee -a "$LOGFILE"
  exit 1
}

# Step 2: Remove old sources.list
echo -e "${YELLOW}[•] Removing old /etc/apt/sources.list...${NC}"
rm -f /etc/apt/sources.list || {
  echo -e "${RED}[✘] Failed to remove sources.list.${NC}" | tee -a "$LOGFILE"
  exit 1
}

# Step 3: Import GPG key
echo -e "${YELLOW}[•] Importing Kali GPG key...${NC}"
gpg --keyserver keyserver.ubuntu.com --recv-keys ED65462EC8D5E4C5 >> "$LOGFILE" 2>&1 || {
  echo -e "${RED}[✘] Failed to receive GPG key.${NC}" | tee -a "$LOGFILE"
  exit 1
}

gpg --export ED65462EC8D5E4C5 | tee /etc/apt/keyrings/kali.gpg > /dev/null || {
  echo -e "${RED}[✘] Failed to export GPG key to /etc/apt/keyrings/kali.gpg.${NC}" | tee -a "$LOGFILE"
  exit 1
}

# Step 4: Write new sources.list
echo -e "${YELLOW}[•] Writing new sources.list...${NC}"
cat <<EOF > /etc/apt/sources.list
deb [signed-by=/etc/apt/keyrings/kali.gpg] http://http.kali.org/kali kali-rolling main non-free contrib
deb-src [signed-by=/etc/apt/keyrings/kali.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

# Step 5: Update APT
echo -e "${YELLOW}[•] Updating APT sources...${NC}"
apt update >> "$LOGFILE" 2>&1 || {
  echo -e "${RED}[✘] APT update failed. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
  exit 1
}

# Step 6: Install apt-transport-https
echo -e "${YELLOW}[•] Installing apt-transport-https...${NC}"
apt install apt-transport-https -y >> "$LOGFILE" 2>&1 || {
    echo -e "${RED}[✘] Failed to install apt-transport-https. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
    exit 1
}

# Step 7: Change sources to HTTPS
echo -e "${YELLOW}[•] Updating mirror links to HTTPS...${NC}"
sed -i 's|http://http.kali.org|https://http.kali.org|g' /etc/apt/sources.list || {
    echo -e "${RED}[✘] Failed to update sources.list to HTTPS.${NC}" | tee -a "$LOGFILE"
    exit 1
}

# Step 8: Update APT again
echo -e "${YELLOW}[•] Updating APT sources again with HTTPS...${NC}"
apt update >> "$LOGFILE" 2>&1 || {
  echo -e "${RED}[✘] Second APT update failed. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
  exit 1
}

# Step 9: Perform full upgrade
echo -e "${YELLOW}[•] Performing full system upgrade... (This may take a while)${NC}"
apt full-upgrade -y >> "$LOGFILE" 2>&1 || {
    echo -e "${RED}[✘] Full upgrade failed. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
    exit 1
}

# Step 10: Autoremove and purge old packages
echo -e "${YELLOW}[•] Removing unused packages...${NC}"
apt autoremove --purge -y >> "$LOGFILE" 2>&1 || {
    echo -e "${RED}[✘] Autoremove failed. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
    exit 1
}

# Step 11: Clean APT cache
echo -e "${YELLOW}[•] Cleaning APT cache...${NC}"
apt clean >> "$LOGFILE" 2>&1 || {
    echo -e "${RED}[✘] APT clean failed. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
    exit 1
}

# Step 12: Install required tools
echo -e "${YELLOW}[•] Installing required tools... (This may also take a while)${NC}"
requirement_tools=(
    python3 python3-pip golang metasploit-framework massdns snapd knockpy sublist3r host nmap
    photon arjun dirbuster dig dnsutils dirb cewl feroxbuster jq npm
    chromium-browser fish parallel tmux unzip make gcc
)
apt install -y "${requirement_tools[@]}" >> "$LOGFILE" 2>&1 || {
    echo -e "${RED}[✘] Failed to install one or more tools. Check $LOGFILE for details.${NC}" | tee -a "$LOGFILE"
    exit 1
}

# Step 13: Setup Go path
echo -e "${YELLOW}[•] Setting up Go environment path...${NC}"
# Find the actual user's home directory, not root's, if run with sudo
REAL_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    echo 'export PATH="$PATH:'"$USER_HOME"'/go/bin"' >> "$USER_HOME/.bashrc"
    echo 'export PATH="$PATH:'"$USER_HOME"'/go/bin"' >> "$USER_HOME/.zshrc"
else
    # Fallback for root or if user cannot be determined
    echo 'export PATH="$PATH:~/go/bin"' >> ~/.bashrc
    echo 'export PATH="$PATH:~/go/bin"' >> ~/.zshrc
fi

echo -e "${GREEN}[✓] Kali sources setup and system configuration completed successfully!${NC}"
echo -e "${YELLOW}[➤] The system will reboot in 5 seconds...${NC}"
sleep 5

# Step 14: Reboot the system
reboot
