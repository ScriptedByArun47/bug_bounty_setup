#!/bin/bash

# usage ./recon_domain.sh target.com


if [ -z "$1" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

domain=$1
$GITHUB_TOKEN=<TOKEN>

mkdir -p recon/$domain
cd recon/$domain || exit

echo "[+] subdomain enumeration ...."
echo "[+] running subfinder.."
subfinder -silent -d $domain -all -recursive  -o subfinder.txt

echo "[+] running assetfinder.."
assetfinder --subs-only $domain > assetfinder.txt

echo "[+] running crt sources..."
curl -s "https://crt.sh/?q=%25.$domain&output=json" \
| jq -r '.[].name_value' 2>/dev/null \
| sed 's/\*\.//g' \
| sort -u > crt_subs.txt

curl -s "https://api.certspotter.com/v1/issuances?domain=$domain&include_subdomains=true&expand=dns_names" \
| jq -r '.[].dns_names[]' 2>/dev/null \
| sed 's/\*\.//g' \
| sort -u > certspotter.txt

echo "[+] running github-subdomains.."
github-subdomains -d $domain -t $GITHUB_TOKEN -o github_subs.txt

echo "[+] merging result.."
cat subfinder.txt assetfinder.txt  crt_subs.txt certspotter.txt github-subdomains| sort -u > subdomain_$domain.txt


echo "[+] resolving live hosts.."
httpx -silent -l subdomain_$domain.txt  -o live_$domain.txt

echo "[+] Recon completed!"
echo "Results saved in recon/$domain/"
