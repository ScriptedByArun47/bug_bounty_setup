#!/bin/bash

set -e

echo "[+] Bug Bounty Tools Installer Started"

# ===== COLORS =====
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
END="\e[0m"

# ===== CHECK ROOT =====
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Run as root: sudo bash bb-tools-install.sh${END}"
   exit 1
fi

# ===== DEPENDENCIES =====
echo -e "${GREEN}[+] Installing dependencies...${END}"
apt update -y
apt install -y git curl wget python3 python3-pip dnsutils build-essential jq unzip

# ===== GO INSTALL =====
if ! command -v go &>/dev/null; then
    echo -e "${YELLOW}[!] Installing Go...${END}"
    apt install -y golang
else
    echo -e "${GREEN}[✓] Go already installed${END}"
fi

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# ===== FUNCTION =====
install_go_tool () {
    TOOL=$1
    BIN=$2
    if command -v $BIN &>/dev/null; then
        echo -e "${GREEN}[✓] $BIN already installed${END}"
    else
        echo -e "${YELLOW}[+] Installing $BIN...${END}"
        go install $TOOL@latest
    fi
}

# ===== GO TOOLS =====
install_go_tool github.com/projectdiscovery/subfinder/v2/cmd/subfinder subfinder
install_go_tool github.com/owasp-amass/amass/v4/... amass
install_go_tool github.com/projectdiscovery/httpx/cmd/httpx httpx
install_go_tool github.com/projectdiscovery/dnsx/cmd/dnsx dnsx
install_go_tool github.com/projectdiscovery/katana/cmd/katana katana
install_go_tool github.com/projectdiscovery/ffuf ffuf
install_go_tool github.com/projectdiscovery/shuffledns/cmd/shuffledns shuffledns
install_go_tool github.com/lc/gau/v2/cmd/gau gau
install_go_tool github.com/tomnomnom/waybackurls waybackurls
install_go_tool github.com/tomnomnom/gf gf
install_go_tool github.com/tomnomnom/qsreplace qsreplace
install_go_tool github.com/ferreiraklet/arachni_scan arachni_scan 2>/dev/null || true

# ===== PYTHON TOOLS =====
install_python_tool () {
    TOOL=$1
    BIN=$2
    if command -v $BIN &>/dev/null; then
        echo -e "${GREEN}[✓] $BIN already installed${END}"
    else
        echo -e "${YELLOW}[+] Installing $BIN...${END}"
        pip3 install $TOOL
    fi
}

install_python_tool arjun arjun
install_python_tool paramspider paramspider

# ===== GIT TOOLS =====
TOOLS_DIR="/opt/bugbounty"
mkdir -p $TOOLS_DIR

clone_tool () {
    NAME=$1
    REPO=$2
    BIN=$3
    if command -v $BIN &>/dev/null; then
        echo -e "${GREEN}[✓] $BIN already installed${END}"
    else
        echo -e "${YELLOW}[+] Installing $NAME...${END}"
        git clone $REPO $TOOLS_DIR/$NAME
        ln -s $TOOLS_DIR/$NAME/$BIN /usr/local/bin/$BIN 2>/dev/null || true
    fi
}

clone_tool dirsearch https://github.com/maurosoria/dirsearch dirsearch.py
clone_tool feroxbuster https://github.com/epi052/feroxbuster feroxbuster
clone_tool CloudEnum https://github.com/initstring/cloud_enum cloud_enum.py
clone_tool AWSBucketDump https://github.com/jordanpotti/AWSBucketDump AWSBucketDump.py
clone_tool SubBrute https://github.com/TheRook/subbrute subbrute.py
clone_tool LinkFinder https://github.com/GerbenJavado/LinkFinder linkfinder.py

# ===== FINAL =====
echo -e "${GREEN}[✓] Installation completed successfully!${END}"
echo -e "${GREEN}[✓] Restart terminal or run: source ~/.bashrc${END}"

