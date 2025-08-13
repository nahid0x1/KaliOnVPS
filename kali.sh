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
  echo -e "${RED}[✘] Failed to create keyrings directory.${NC}"
  exit 1
}

# Step 2: Remove old sources.list
echo -e "${YELLOW}[•] Removing old /etc/apt/sources.list...${NC}"
rm -f /etc/apt/sources.list || {
  echo -e "${RED}[✘] Failed to remove sources.list.${NC}"
  exit 1
}

# Step 3: Import GPG key
echo -e "${YELLOW}[•] Importing Kali GPG key...${NC}"
gpg --keyserver keyserver.ubuntu.com --recv-keys ED65462EC8D5E4C5 >> "$LOGFILE" 2>&1 || {
  echo -e "${RED}[✘] Failed to receive GPG key.${NC}"
  exit 1
}

gpg --export ED65462EC8D5E4C5 | tee /etc/apt/keyrings/kali.gpg > /dev/null || {
  echo -e "${RED}[✘] Failed to export GPG key to /etc/apt/keyrings/kali.gpg.${NC}"
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
  echo -e "${RED}[✘] APT update failed. Check $LOGFILE for details.${NC}"
  exit 1
}


# step 6
echo -e "${YELLOW}[•] Upgrading System...${NC}"
apt install apt-transport-https -y

# Step 8: HTTP To HTTPS.list
echo -e "${YELLOW}[•] HTTP to HTTPS /etc/apt/sources.list...${NC}"
rm -f /etc/apt/sources.list || {
  echo -e "${RED}[✘] Failed to remove sources.list.${NC}"
  exit 1
}

# Step 7: Write new sources.list
echo -e "${YELLOW}[•] Writing HTTPS sources.list...${NC}"
cat <<EOF > /etc/apt/sources.list
deb [signed-by=/etc/apt/keyrings/kali.gpg] https://http.kali.org/kali kali-rolling main non-free contrib
deb-src [signed-by=/etc/apt/keyrings/kali.gpg] https://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

# Step 8: Update APT
echo -e "${YELLOW}[•] Updating APT sources...${NC}"
apt update >> "$LOGFILE" 2>&1 || {
  echo -e "${RED}[✘] APT update failed. Check $LOGFILE for details.${NC}"
  exit 1
}


# Step 9: APT Cache Clean
echo -e "${YELLOW}[•] Cache Clear...${NC}"
apt autoremove --purge -y && apt clean >> "$LOGFILE" 2>&1 || {
  echo -e "${RED}[✘]  Cache clean failed. Check $LOGFILE for details.${NC}"
  exit 1
}

echo -e "${GREEN}[✓] Kali sources setup completed successfully!${NC}"
echo -e "${GREEN}[✓] System Rebooting......!${NC}"

reboot
