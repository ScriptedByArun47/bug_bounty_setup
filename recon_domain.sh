#!/bin/bash

# ==============================
# PRO RECON FRAMEWORK v2
# Usage: ./recon_domain.sh target.com
# ==============================

set -e
set -o pipefail

# ------------------------------
# Check argument
# ------------------------------
if [ -z "$1" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

domain=$1

# ------------------------------
# Check required tools
# ------------------------------
for tool in subfinder assetfinder amass dnsx httpx alterx naabu shuffledns jq curl gau github-subdomains; do
  if ! command -v $tool &> /dev/null; then
    echo "[!] $tool not installed. Install it first."
    exit 1
  fi
done

# ------------------------------
# Create directory
# ------------------------------
mkdir -p recon/$domain
cd recon/$domain || exit

echo "================================="
echo "[+] Starting Recon on $domain"
echo "================================="

# ==============================
# PASSIVE RECON (Parallel)
# ==============================

echo "[+] Running Passive Enumeration..."

subfinder -silent -d $domain -all -recursive -rl 15 -o subfinder.txt &
assetfinder --subs-only $domain > assetfinder.txt &
amass enum -passive -d $domain -silent -norecursive > amass_passive.txt &

# crt.sh
(
curl -s "https://crt.sh/?q=%25.${domain}&output=json" \
| jq -r '.[].name_value' 2>/dev/null \
| sed 's/\*\.//g' \
| sort -u > crt_subs.txt
) &

# certspotter
(
curl -s "https://api.certspotter.com/v1/issuances?domain=${domain}&include_subdomains=true&expand=dns_names" \
| jq -r '.[].dns_names[]' 2>/dev/null \
| sed 's/\*\.//g' \
| grep -E "\.?${domain}$" \
| sort -u > certspotter.txt
) &

# GitHub Subdomains
if [ -n "$GITHUB_TOKEN" ]; then
  github-subdomains -d $domain -t $GITHUB_TOKEN -q -o github_subs.txt &
else
  echo "[!] GITHUB_TOKEN not set. Skipping github-subdomains."
  touch github_subs.txt
fi

wait

# ------------------------------
# Merge passive results
# ------------------------------
echo "[+] Merging passive results..."
cat subfinder.txt assetfinder.txt crt_subs.txt certspotter.txt github_subs.txt amass_passive.txt \
| sort -u > subdomains_passive.txt

echo "[+] Passive subdomains: $(wc -l < subdomains_passive.txt)"

# ==============================
# SUBDOMAIN MUTATION
# ==============================

grep -E "\.${domain}$" subdomains_passive.txt > filtered_subdomains.txt

echo "[+] Running alterx mutation..."
alterx -l filtered_subdomains.txt -limit 20000 -o mutated.txt

# ==============================
# ACTIVE RECON
# ==============================

echo "[+] Resolving passive subdomains..."
dnsx -l subdomains_passive.txt -silent  -o resolved_passive.txt

echo "[+] Running amass active mode..."
amass enum -active -d $domain -silent  -o amass_active.txt




echo "[+] Resolving mutated subdomains..."
shuffledns -d $domain -l mutated.txt \
-r /home/fmask/regulator/resolvers.txt \
-mode resolve -silent -t 10000  -sw \
-o resolved_mutated.txt

# ------------------------------
# Merge final subdomains
# ------------------------------
cat resolved_passive.txt resolved_mutated.txt amass_active.txt \
| sort -u > final_subdomains.txt

echo "[+] Final resolved subdomains: $(wc -l < final_subdomains.txt)"

# ==============================
# LIVE HOST DETECTION
# ==============================

echo "[+] Running httpx..."
httpx -silent -l final_subdomains.txt \
-title -sc -cl -location -td \
-o live_hosts.txt

echo "[+] Live hosts: $(wc -l < live_hosts.txt)"

# ==============================
# PORT SCANNING
# ==============================

echo "[+] Running naabu (top 1000 ports)..."
naabu -l final_subdomains.txt -top-ports 1000 -silent \
| httpx -silent -title -sc -o web_recon.txt

#: <<'testing'
echo "[+] port scanning..."
echo "[+] Running full TCP scan on live hosts"
naabu -l live_hosts.txt -p- -rate 2000 -silent > all_open_ports.txt

echo "[+] Running deep Nmap service detection...."

while read host; do
  echo "[+] scanning $host"
  sudo nmap -sV -sC -T4 "$host" -oN nmap_$host.txt 
done < line_hosts.txt


  echo "[+] Running HTTP enum scripts..."
  while read host; do
      sudo nmap -p 80,443,8080,8443 \
      --script http-enum,http-title,http-headers \
      "$host" -oN web_enum_$host.txt
  done < live_hosts.txt


# ==============================
# URL COLLECTION
# ==============================

echo "[+] Collecting URLs with gau..."
cat live_hosts.txt | gau > gau_urls.txt




# ==============================
# DONE
# ==============================

echo "================================="
echo "[+] Recon Completed Successfully!"
echo "[+] Results saved in recon/$domain/"
echo "================================="
