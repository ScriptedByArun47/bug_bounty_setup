#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

echo -e "${YELLOW}🔍 Verifying installed security tools...\n${NC}"

tools=(
  nmap
  subfinder
  assetfinder
  amass
  httpx
  httprobe
  nuclei
  ffuf
  gobuster
  sqlmap
  dalfox
  gf
  gau
  waybackurls
  katana
  hakrawler
  arjun
  paramspider
  linkfinder
  jq
  curl
  wget
  python3
  pip
  pipx
)

for tool in "${tools[@]}"; do
  if command -v "$tool" &>/dev/null; then
    path=$(command -v "$tool")
    version=$($tool --version 2>/dev/null | head -n 1)
    echo -e "${GREEN}[✔] $tool${NC}"
    echo -e "    Path: $path"
    [[ -n "$version" ]] && echo -e "    Version: $version"
  else
    echo -e "${RED}[✘] $tool NOT installed${NC}"
  fi
  echo
done

echo -e "${YELLOW}✅ Verification completed.${NC}"

