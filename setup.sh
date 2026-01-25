#!/bin/bash
set -e

echo "[+] Updating system"
sudo apt update && sudo apt upgrade -y

echo "[+] Installing base dependencies"
sudo apt install -y \
  git curl wget unzip jq build-essential \
  python3 python3-pip \
  golang-go \
  nmap masscan \
  chromium

echo "[+] Setting Go env"
if ! grep -q GOPATH ~/.bashrc; then
  echo 'export GOPATH=$HOME/go' >> ~/.bashrc
  echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
fi
source ~/.bashrc

echo "[+] Installing Go tools"

go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/httprobe@latest
go install github.com/tomnomnom/gf@latest

go install github.com/hahwul/dalfox/v2@latest
go install github.com/ffuf/ffuf/v2@latest

echo "[+] Installing Findomain"
wget -q https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip
unzip -o findomain-linux.zip
chmod +x findomain
sudo mv findomain /usr/local/bin/
rm findomain-linux.zip

echo "[+] Installing Amass"
sudo apt install -y amass

echo "[+] Updating nuclei templates"
nuclei -update-templates

echo "[+] Setup complete!"
echo "[+] Restart terminal or run: source ~/.bashrc"
